const std = @import("std");
const zig = @import("builtin");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const cfg = std.Build.TestOptions{
        .name = "zig-sdl3",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/sdl3.zig"),
        .version = .{
            .major = 0,
            .minor = 1,
            .patch = 0,
        },
    };

    const sdl_dep = b.dependency("sdl", .{
        .target = target,
        .optimize = optimize,
    });
    const sdl_dep_lib = sdl_dep.artifact("SDL3");

    const sdl_image_dep = b.dependency("sdl_image", .{
        .target = target,
        .optimize = optimize,
        //TODO add options here...
    });
    const sdl_image_lib = sdl_image_dep.artifact("SDL3_image");

    const sdl3 = b.addModule("sdl3", .{
        .root_source_file = cfg.root_source_file,
        .target = target,
        .optimize = optimize,
    });
    const main_callbacks = b.option(bool, "callbacks", "Enable SDL callbacks rather than use a main function") orelse false;
    if (main_callbacks) {
        sdl3.addCSourceFile(.{ .file = b.path("main_callbacks.c") });
    }
    const extension_options = b.addOptions();
    const ext_image = b.option(bool, "ext_image", "Enable SDL_image extension") orelse false;
    extension_options.addOption(bool, "image", ext_image);
    // linking zig-sdl to sdl3, makes the library much easier to use
    sdl3.addOptions("extension_options", extension_options);
    sdl3.linkLibrary(sdl_dep_lib);
    if (ext_image) {
        sdl3.linkLibrary(sdl_image_lib);
    }

    _ = setupTest(b, cfg, extension_options);
    _ = try setupExamples(b, sdl3, cfg);
    _ = try runExample(b, sdl3, cfg);
}

pub fn setupExample(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions, name: []const u8) !*std.Build.Step.Compile {
    const exe = b.addExecutable(.{
        .name = name,
        .target = cfg.target orelse b.standardTargetOptions(.{}),
        .optimize = cfg.optimize,
        .root_source_file = b.path(try std.fmt.allocPrint(b.allocator, "examples/{s}.zig", .{name})),
        .version = cfg.version,
    });
    exe.root_module.addImport("sdl3", sdl3);
    b.installArtifact(exe);
    return exe;
}

pub fn runExample(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions) !void {
    const run_example: ?[]const u8 = b.option([]const u8, "example", "The example name for running an example") orelse null;
    const run = b.step("run", "Run an example with -Dexample=<example_name> option");
    if (run_example) |example| {
        const run_art = b.addRunArtifact(try setupExample(b, sdl3, cfg, example));
        run_art.step.dependOn(b.getInstallStep());
        run.dependOn(&run_art.step);
    }
}

pub fn setupExamples(b: *std.Build, sdl3: *std.Build.Module, cfg: std.Build.TestOptions) !*std.Build.Step {
    const exp = b.step("examples", "Build all examples");
    const examples_dir = b.path("examples");
    var dir = (try std.fs.openDirAbsolute(examples_dir.getPath(b), .{ .iterate = true }));
    defer dir.close();
    var dir_iterator = try dir.walk(b.allocator);
    defer dir_iterator.deinit();
    while (try dir_iterator.next()) |file| {
        if (file.kind == .file and std.mem.endsWith(u8, file.basename, ".zig")) {
            _ = try setupExample(b, sdl3, cfg, file.basename[0 .. file.basename.len - 4]);
        }
    }
    exp.dependOn(b.getInstallStep());
    return exp;
}

pub fn setupTest(b: *std.Build, cfg: std.Build.TestOptions, extension_options: *std.Build.Step.Options) *std.Build.Step.Compile {
    const tst = b.addTest(cfg);
    tst.root_module.addOptions("extension_options", extension_options);
    const sdl_dep = b.dependency("sdl", .{
        .target = cfg.target orelse b.standardTargetOptions(.{}),
        .optimize = cfg.optimize,
    });
    const sdl_dep_lib = sdl_dep.artifact("SDL3");
    tst.linkLibrary(sdl_dep_lib);
    const tst_run = b.addRunArtifact(tst);
    const tst_step = b.step("test", "Run all tests");
    tst_step.dependOn(&tst_run.step);
    return tst;
}
