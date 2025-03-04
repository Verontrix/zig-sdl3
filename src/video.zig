const C = @import("c.zig").C;
const errors = @import("errors.zig");
const pixels = @import("pixels.zig");
const properties = @import("properties.zig");
const rect = @import("rect.zig");
const std = @import("std");
const surface = @import("surface.zig");

/// System theme.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const SystemTheme = enum(c_uint) {
    /// Light colored theme.
    Light = C.SDL_SYSTEM_THEME_LIGHT,
    /// Dark colored theme.
    Dark = C.SDL_SYSTEM_THEME_DARK,
};

/// This is a unique for a display for the time it is connected to the system, and is never reused for the lifetime of the application.
///
/// ## Remarks
/// If the display is disconnected and reconnected, it will get a new ID.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const Display = packed struct {
    value: C.SDL_DisplayID,

    /// Display properties.
    ///
    /// ## Version
    /// Provided by zig-sdl3.
    pub const Properties = struct {
        /// True if the display has HDR headroom above the SDR white point.
        /// This is for informational and diagnostic purposes only, as not all platforms provide this information at the display level.
        hdr_enabled: ?bool,
        /// The "panel orientation" property for the display in degrees of clockwise rotation.
        /// Note that this is provided only as a hint, and the application is responsible for any coordinate transformations needed to conform to the requested display orientation.
        kmsdrm_panel_orientation: ?i64,

        /// Get properties from SDL.
        pub fn fromSdl(props: properties.Group) Properties {
            return .{
                .hdr_enabled = if (props.get(C.SDL_PROP_DISPLAY_HDR_ENABLED_BOOLEAN)) |val| val.Boolean else null,
                .kmsdrm_panel_orientation = if (props.get(C.SDL_PROP_DISPLAY_KMSDRM_PANEL_ORIENTATION_NUMBER)) |val| val.Number else null,
            };
        }
    };

    /// Get a list of currently connected displays.
    ///
    /// ## Return Value
    /// Returns a pointer of display items that will be terminated by a value of 0.
    /// Return value must be freed with `stdinc.free()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn getAll() ![*:0]Display {
        var count: c_int = undefined;
        const ret = try errors.wrapCallCPtr(C.SDL_DisplayID, C.SDL_GetDisplays(&count));
        return @as([*:0]Display, ret);
    }

    /// Get the desktop area represented by a display.
    ///
    /// ## Function Parameters
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// The rectangle filled in with the display bounds.
    ///
    /// ## Remarks
    /// The primary display is often located at (0,0), but may be placed at a different location depending on monitor layout.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getBounds(
        self: Display,
    ) !rect.IRect {
        var area: C.SDL_Rect = undefined;
        const ret = C.SDL_GetDisplayBounds(
            self.value,
            &area,
        );
        try errors.wrapCallBool(ret);
        return rect.IRect.fromSdl(area);
    }

    /// Get the closest match to the requested display mode.
    ///
    /// ## Function Parameters
    /// * `self`: h
    /// * `width`: h
    /// * `height`: h
    /// * `refresh_rate`: h
    /// * `include_high_density_modes`: h
    ///
    /// ## Return Value
    /// A display mode with the closest display mode equal to or larger than the desired mode.
    /// Will return an error if any mode could not be found, or all modes are smaller.
    ///
    /// ## Remarks
    /// The available display modes are scanned and closest is filled in with the closest mode matching the requested mode and returned.
    /// The mode format and refresh rate default to the desktop mode if they are set to 0.
    /// The modes are scanned with size being first priority, format being second priority, and finally checking the refresh rate.
    /// If all the available modes are too small, then an error is returned.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getClosestFullscreenMode(
        self: Display,
        width: usize,
        height: usize,
        refresh_rate: f32,
        include_high_density_modes: bool,
    ) !DisplayMode {
        var mode: C.SDL_DisplayMode = undefined;
        const ret = C.SDL_GetClosestFullscreenDisplayMode(
            self.value,
            @intCast(width),
            @intCast(height),
            refresh_rate,
            include_high_density_modes,
            &mode,
        );
        try errors.wrapCallBool(ret);
        return DisplayMode.fromSdl(mode);
    }

    /// Get the content scale of a display.
    ///
    /// ## Function Parameters
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// Returns the content scale of the display.
    ///
    /// ## Remarks
    /// The content scale is the expected scale for content based on the DPI settings of the display.
    /// For example, a 4K display might have a 2.0 (200%) display scale,
    /// which means that the user expects UI elements to be twice as big on this display, to aid in readability.
    ///
    /// After window creation, `video.Window.getDisplayScale()` should be used to query the content scale factor
    /// for individual windows instead of querying the display for a window and calling this function,
    /// as the per-window content scale factor may differ from the base value of the display it is on,
    /// particularly on high-DPI and/or multi-monitor desktop configurations.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getContentScale(
        self: Display,
    ) !f32 {
        const ret = C.SDL_GetDisplayContentScale(
            self.value,
        );
        return errors.wrapCall(f32, ret, 0.0);
    }

    /// Get information about the current display mode.
    ///
    /// ## Function Parameters
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// Returns the desktop display mode.
    ///
    /// ## Remarks
    /// There's a difference between this function and `video.Display.getDesktopMode()` when SDL runs fullscreen and has changed the resolution.
    /// In that case this function will return the current display mode, and not the previous native display mode.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getCurrentMode(
        self: Display,
    ) !DisplayMode {
        const ret = C.SDL_GetCurrentDisplayMode(self.value);
        const mode = try errors.wrapNull(C.SDL_DisplayMode, ret);
        return DisplayMode.fromSdl(mode);
    }

    /// Get the orientation of a display.
    ///
    /// ## Function Parameters
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// Returns the orientation value of the display.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getCurrentOrientation(
        self: Display,
    ) ?DisplayOrientation {
        const ret = C.SDL_GetCurrentDisplayOrientation(
            self.value,
        );
        return DisplayOrientation.fromSdl(ret);
    }

    /// Get information about the desktop's display mode.
    ///
    /// ## Function Parameter
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// Returns the desktop display mode.
    ///
    /// ## Remarks
    /// There's a difference between this function and `video.Display.getCurrentMode()` when SDL runs fullscreen and has changed the resolution.
    /// In that case this function will return the previous native display mode, and not the current display mode.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getDesktopMode(
        self: Display,
    ) !DisplayMode {
        const ret = C.SDL_GetDesktopDisplayMode(self.value);
        const val = try errors.wrapCallCPtrConst(C.SDL_DisplayMode, ret);
        return DisplayMode.fromSdl(val.*);
    }

    /// Get a list of fullscreen display modes available on a display.
    ///
    /// ## Function Parameter
    /// * `self`: The display to query.
    /// * `allocator`: Allocator used to allocator the display modes.
    ///
    /// ## Return Value
    /// Returns a slice of display modes, this needs to be freed.
    ///
    /// ## Remarks
    /// The display modes are sorted in this priority:.
    /// * Width -> Largest to smallest.
    /// * Height -> Largest to smallest.
    /// * Bits per pixel -> More colors to fewer colors.
    /// * Packed pixel layout -> Largest to smallest.
    /// * Refresh rate -> Highest to lowest.
    /// * Pixel density -> Lowest to highest.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getFullscreenModes(
        self: Display,
        allocator: std.mem.Allocator,
    ) ![]DisplayMode {
        var count: c_int = undefined;
        const val = try errors.wrapCallCPtr([*c]C.SDL_DisplayMode, C.SDL_GetFullscreenDisplayModes(self.value, &count));
        var ret = try allocator.alloc(DisplayMode, @intCast(count));
        for (0..count) |ind| {
            ret[ind] = DisplayMode.fromSdl(val[ind].*);
        }
        return ret;
    }

    /// Get the name of a display in UTF-8 encoding.
    ///
    /// ## Function Parameters
    /// * `self` - The display to query.
    ///
    /// ## Return Value
    /// Returns the name of a display.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn getName(
        self: Display,
    ) ![]const u8 {
        const ret = C.SDL_GetDisplayName(
            self.value,
        );
        return try errors.wrapCallCString(ret);
    }

    /// Get the orientation of a display when it is unrotated.
    ///
    /// ## Function Parameters
    /// * `self` - The display to query.
    ///
    /// ## Return Value
    /// Returns the display orientation value enum of the display.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getNaturalOrientation(
        self: Display,
    ) ?DisplayOrientation {
        const ret = C.SDL_GetNaturalDisplayOrientation(
            self.value,
        );
        if (ret == C.SDL_ORIENTATION_UNKNOWN)
            return null;
        return @enumFromInt(ret);
    }

    /// Return the primary display.
    ///
    /// ## Return Value
    /// Returns the primary display.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getPrimaryDisplay() !Display {
        const ret = C.SDL_GetPrimaryDisplay();
        return Display{ .value = try errors.wrapCall(C.SDL_DisplayID, ret, 0) };
    }

    /// Get the properties associated with a display.
    ///
    /// ## Function Parameters
    /// * `self` - The display to query.
    ///
    /// ## Return Value
    /// Returns the display properties.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO!!!
    pub fn getProperties(
        self: Display,
    ) !Properties {
        const ret = C.SDL_GetDisplayProperties(self.value);
        return Properties.fromSdl(properties.Group{ .value = try errors.wrapCall(C.SDL_PropertiesID, ret, 0) });
    }

    /// Get the usable desktop area represented by a display, in screen coordinates.
    ///
    /// ## Function Parameters
    /// * `self`: The display to query.
    ///
    /// ## Return Value
    /// The rectangle filled in with the display bounds.
    ///
    /// ## Remarks
    /// This is the same area as `video.Display.getBounds()` reports, but with portions reserved by the system removed.
    /// For example, on Apple's macOS, this subtracts the area occupied by the menu bar and dock.
    ///
    /// Setting a window to be fullscreen generally bypasses these unusable areas, so these are good guidelines for the maximum space available to a non-fullscreen window.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getUsableBounds(
        self: Display,
    ) !rect.IRect {
        var area: C.SDL_Rect = undefined;
        const ret = C.SDL_GetDisplayUsableBounds(
            self.value,
            &area,
        );
        try errors.wrapCallBool(ret);
        return rect.IRect.fromSdl(area);
    }
};

/// The structure that defines a display mode.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const DisplayMode = struct {
    /// The display this mode is associated with.
    display: ?Display,
    /// Pixel format.
    format: ?pixels.Format,
    /// Width.
    width: usize,
    /// Height.
    height: usize,
    /// Scale converting size to pixels (e.g. a 1920x1080 mode with 2.0 scale would have 3840x2160 pixels).
    pixel_density: f32,
    /// Refresh rate (or 0.0f for unspecified).
    refresh_rate: f32,
    /// Precise refresh rate numerator (or 0 for unspecified).
    refresh_rate_numerator: u32,
    /// Precise refresh rate denominator.
    refresh_rate_denominator: u32,

    /// Convert from SDL.
    pub fn fromSdl(mode: C.SDL_DisplayMode) DisplayMode {
        return .{
            .display = Display.fromSdl(mode.displayID),
            .format = pixels.Format.fromSdl(mode.format),
            .width = @intCast(mode.w),
            .height = @intCast(mode.h),
            .pixel_density = mode.pixel_density,
            .refresh_rate = mode.refresh_rate,
            .refresh_rate_numerator = @intCast(mode.refresh_rate_numerator),
            .refresh_rate_denominator = @intCast(mode.refresh_rate_denominator),
        };
    }

    /// Convert to SDL.
    pub fn toSdl(self: DisplayMode) C.SDL_DisplayMode {
        return .{
            .displayID = Display.toSdl(self.display),
            .format = pixels.Format.toSdl(self.format),
            .w = @intCast(self.width),
            .h = @intCast(self.height),
            .pixel_density = self.pixel_density,
            .refresh_rate = self.refresh_rate,
            .refresh_rate_numerator = @intCast(self.refresh_rate_numerator),
            .refresh_rate_denominator = @intCast(self.refresh_rate_denominator),
        };
    }
};

/// Display orientation values; the way a display is rotated.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const DisplayOrientation = enum(c_uint) {
    /// The display is in landscape mode, with the right side up, relative to portrait mode.
    Landscape = C.SDL_ORIENTATION_LANDSCAPE,
    /// The display is in landscape mode, with the left side up, relative to portrait mode.
    LandscapeFlipped = C.SDL_ORIENTATION_LANDSCAPE_FLIPPED,
    /// The display is in portrait mode.
    Portrait = C.SDL_ORIENTATION_PORTRAIT,
    /// The display is in portrait mode, upside down.
    PortraitFlipped = C.SDL_ORIENTATION_PORTRAIT_FLIPPED,

    /// Convert from SDL.
    pub fn fromSdl(val: C.SDL_DisplayOrientation) ?DisplayOrientation {
        return switch (val) {
            C.SDL_ORIENTATION_LANDSCAPE => .Landscape,
            C.SDL_ORIENTATION_LANDSCAPE_FLIPPED => .LandscapeFlipped,
            C.SDL_ORIENTATION_PORTRAIT => .Portrait,
            C.SDL_ORIENTATION_PORTRAIT_FLIPPED => .PortraitFlipped,
            else => null,
        };
    }

    /// Convert to an SDL value.
    pub fn toSdl(self: ?DisplayOrientation) C.SDL_DisplayOrientation {
        const val = self orelse return C.SDL_ORIENTATION_UNKNOWN;
        switch (val) {
            .Landscape => C.SDL_ORIENTATION_LANDSCAPE,
            .LandscapeFlipped => C.SDL_ORIENTATION_LANDSCAPE_FLIPPED,
            .Portrait => C.SDL_ORIENTATION_PORTRAIT,
            .PortraitFlipped => C.SDL_ORIENTATION_PORTRAIT_FLIPPED,
        }
    }
};

/// Wrapper for EGL related functions.
///
/// ## Version
/// Provided by zig-sdl3.
pub const egl = struct {
    /// An EGL attribute, used when creating an EGL context.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglAttrib = C.SDL_EGLAttrib;

    /// EGL platform attribute initialization callback.
    ///
    /// ## Function Parameters
    /// * `user_data`: An app-controlled pointer that is passed to the callback.
    ///
    /// ## Return Value.
    /// Returns a newly-allocated array of attributes, terminated with `EGL_NONE`.
    ///
    /// ## Remarks
    /// This is called when SDL is attempting to create an EGL context, to let the app add extra attributes to its `eglGetPlatformDisplay()` call.
    ///
    /// The callback should return a pointer to an EGL attribute array terminated with `EGL_NONE`.
    /// If this function returns `null`, the `video.createWindow()` process will fail gracefully.
    ///
    /// The returned pointer should be allocated with `stdinc.malloc()` and will be passed to `stdinc.free()`.
    ///
    /// The arrays returned by each callback will be appended to the existing attribute arrays defined by SDL.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglAttribArrayCallback = *const fn (user_data: ?*anyopaque) callconv(.C) [*c]EglAttrib;

    /// Opaque type for an EGL config.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglConfig = *anyopaque;

    /// Opaque type for an EGL display.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglDisplay = *anyopaque;

    /// An EGL integer attribute, used when creating an EGL surface.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglInt = C.SDL_EGLint;

    /// EGL surface/context attribute initialization callback types.
    ///
    /// ## Function Parameters
    /// * `user_data`: An app-controlled pointer that is passed to the callback.
    /// * `display`: The EGL display to be used.
    /// * `config`: The EGL config to be used.
    ///
    /// ## Return Value
    /// Returns a newly-allocated array of attributes, terminated with `EGL_NONE`.
    ///
    /// ## Remarks
    /// This is called when SDL is attempting to create an EGL surface, to let the app add extra attributes to its `eglCreateWindowSurface()` or `eglCreateContext()` calls.
    ///
    /// For convenience, the `EGLDisplay` and `EGLConfig` to use are provided to the callback.
    ///
    /// The callback should return a pointer to an EGL attribute array terminated with `EGL_NONE`.
    /// If this function returns `null`, the SDL_CreateWindow process will fail gracefully.
    ///
    /// The returned pointer should be allocated with `stdinc.malloc()` and will be passed to `stdinc.free()`.
    ///
    /// The arrays returned by each callback will be appended to the existing attribute arrays defined by SDL.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglIntArrayCallback = *const fn (user_data: ?*anyopaque, display: C.SDL_EGLDisplay, config: C.SDL_EGLConfig) callconv(.C) [*c]EglInt;

    /// Opaque type for an EGL surface.
    ///
    /// ## Version
    /// This datatype is available since SDL 3.2.0.
    pub const EglSurface = *anyopaque;

    /// Get the currently active EGL config.
    ///
    /// ## Return Value
    /// Returns the currently active EGL config.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getCurrentConfig() !EglConfig {
        const ret = C.SDL_EGL_GetCurrentConfig();
        return errors.wrapNull(EglConfig, ret);
    }

    /// Get the currently active EGL display.
    ///
    /// ## Return Value
    /// Returns the currently active EGL display.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getCurrentDisplay() !EglDisplay {
        const ret = C.SDL_EGL_GetCurrentDisplay();
        return errors.wrapNull(EglDisplay, ret);
    }

    /// Get an EGL library function by name.
    ///
    /// ## Function Parameters
    /// * `proc`: The name of the EGL function.
    ///
    /// ## Return Value
    /// Returns a pointer to the named EGL function.
    /// The returned pointer should be cast to the appropriate function signature.
    ///
    /// ## Remarks
    /// If an EGL library is loaded, this function allows applications to get entry points for EGL functions.
    /// This is useful to provide to an EGL API and extension loader.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getProcAddress(
        proc: [:0]const u8,
    ) !*anyopaque {
        const ret = C.SDL_EGL_GetProcAddress(proc.ptr);
        return errors.wrapNull(*anyopaque, ret);
    }

    /// Get the EGL surface associated with the window.
    ///
    /// ## Function Parameters
    /// * `window`: The window to query.
    ///
    /// ## Return value.
    /// Returns the pointer to the surface.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getWindowSurface(
        window: Window,
    ) !EglSurface {
        const ret = C.SDL_EGL_GetWindowSurface(window.value);
        return errors.wrapNull(EglSurface, ret);
    }

    /// Sets the callbacks for defining custom `EGLAttrib` arrays for EGL initialization.
    ///
    /// ## Function Parameters
    /// * `platform_attrib_callback`: Callback for attributes to pass to `eglGetPlatformDisplay()`. May be `null`.
    /// * `surface_attrib_callback`: Callback for attributes to pass to `eglCreateSurface()`. May be `null`.
    /// * `context_attrib_callback`: Callback for attributes to pass to `eglCreateContext()`. May be `null`.
    /// * `user_data`: A pointer that is passed to the callbacks.
    ///
    /// ## Remarks
    /// Callbacks that aren't needed can be set to `null`.
    ///
    /// NOTE: These callback pointers will be reset after `video.gl.resetAttributes()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn setAttributeCallbacks(
        platform_attrib_callback: ?EglAttribArrayCallback,
        surface_attrib_callback: ?EglIntArrayCallback,
        context_attrib_callback: ?EglIntArrayCallback,
        user_data: ?*anyopaque,
    ) void {
        C.SDL_EGL_SetAttributeCallbacks(
            platform_attrib_callback,
            surface_attrib_callback,
            context_attrib_callback,
            user_data,
        );
    }
};

/// Window flash operation.
///
/// ## Version
/// This enum is available since SDL 3.2.0.
pub const FlashOperation = enum(c_uint) {
    /// Cancel any window flash state.
    Cancel = C.SDL_FLASH_CANCEL,
    /// Flash the window briefly to get attention
    Briefly = C.SDL_FLASH_BRIEFLY,
    /// Flash the window until it gets focus
    UntilFocused = C.SDL_FLASH_UNTIL_FOCUSED,

    /// Convert from SDL.
    pub fn fromSdl(val: C.SDL_FlashOperation) FlashOperation {
        return @enumFromInt(val);
    }

    /// Convert to SDL.
    pub fn toSdl(self: FlashOperation) C.SDL_FlashOperation {
        return @intFromEnum(self);
    }
};

/// The struct used as an opaque handle to a window.
///
/// ## Version
/// This struct is available since SDL 3.2.0.
pub const Window = packed struct {
    value: *C.SDL_Window,

    /// Supported properties for creating a window.
    ///
    /// ## Version
    /// This struct is available since SDL 3.2.0.
    pub const CreateProperties = struct {
        /// True if the window should always be on top.
        always_on_top: ?bool = null,
        /// True if the window has no window decoration.
        borderless: ?bool = null,
        /// True if the window will be used with an externally managed graphics context.
        external_graphics_context: ?bool = null,
        /// True if the window should accept keyboard input (defaults true).
        focusable: ?bool = null,
        /// True if the window should start in fullscreen mode in desktop resolution.
        fullscreen: ?bool = null,
        /// The height of the window.
        height: ?u32 = null,
        /// True if the window should start hidden.
        hidden: ?bool = null,
        /// True if the window uses a high pixel density buffer if possible.
        high_pixel_density: ?bool = null,
        /// True if the window should start maximized.
        maximized: ?bool = null,
        /// True if the window is a popup menu.
        menu: ?bool = null,
        /// True if the window will be used with metal rendering.
        metal: ?bool = null,
        /// True if the window should start minimized.
        minimized: ?bool = null,
        /// True if the window is modal to its parent.
        modal: ?bool = null,
        /// True if the window starts with grabbed mouse focus.
        mouse_grabbed: ?bool = null,
        /// True if the window will be used with OpenGL rendering.
        open_gl: ?bool = null,
        /// Window that will be the parent of this window, required for windows with the "tooltip", "menu", and "modal" properties.
        parent: ?Window = null,
        /// True if the window should be resizable.
        resizable: bool = null,
        /// The title of the window, in UTF-8 encoding.
        title: ?[:0]const u8 = null,
        /// True if the window shows transparent in the areas with alpha of 0.
        transparent: ?bool = null,
        /// True if the window is a tooltip.
        tooltip: ?bool = null,
        /// True if the window is a utility window, not showing in the task bar and window list.
        utility: ?bool = null,
        /// True if the window will be used with Vulkan rendering.
        vulkan: ?bool = null,
        /// The width of the window.
        width: ?u32 = null,
        /// The x position of the window.
        x: ?Position = null,
        /// The y position of the window.
        y: ?Position = null,
        /// MacOS only.
        /// The (`__unsafe_unretained`) `NSWindow` associated with the window, if you want to wrap an existing window.
        cocoa_window: ??*anyopaque = null,
        /// MacOS only.
        /// The (`__unsafe_unretained`) `NSView` associated  the window, defaults to `[window contentView]`
        cocoa_view: ??*anyopaque = null,
        /// Wayland only.
        /// True if the application wants to use the Wayland surface for a custom role and does not want it attached to an XDG toplevel window.
        /// See SDL3's README/wayland for more information on using custom surfaces.
        wayland_surface_role_custom: ?bool = null,
        /// Wayland only.
        /// True if the application wants an associated `wl_egl_window object` to be created and attached to the window,
        /// even if the window does not have the OpenGL property or `video.WindowFlags.open_gl` flag set.
        wayland_create_egl_window: ?bool = null,
        /// Wayland only.
        /// The `wl_surface` associated with the window, if you want to wrap an existing window.
        /// See README/wayland for more information on SDL3's github.
        wayland_create_wl_surface: ??*anyopaque = null,
        /// Windows only.
        /// The `HWND` associated with the window, if you want to wrap an existing window.
        win32_hwnd: ??*anyopaque = null,
        /// Windows only.
        /// Optional, another window to share pixel format with, useful for OpenGL windows.
        win32_pixel_format_hwnd: ??*anyopaque = null,
        /// x11 only.
        /// The X11 Window associated with the window, if you want to wrap an existing window.
        x11_window: ?i64 = null,

        /// Create SDL3 properties from this properties structure.
        ///
        /// Returned properties must be `deinit()` manually.
        pub fn toProperties(
            self: CreateProperties,
        ) !properties.Group {
            const ret = try properties.Group.init();
            if (self.always_on_top) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_ALWAYS_ON_TOP_BOOLEAN, .{ .Boolean = val });
            if (self.borderless) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_BORDERLESS_BOOLEAN, .{ .Boolean = val });
            if (self.external_graphics_context) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_EXTERNAL_GRAPHICS_CONTEXT_BOOLEAN, .{ .Boolean = val });
            if (self.focusable) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_FOCUSABLE_BOOLEAN, .{ .Boolean = val });
            if (self.fullscreen) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_FULLSCREEN_BOOLEAN, .{ .Boolean = val });
            if (self.height) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_HEIGHT_NUMBER, .{ .Number = @intCast(val) });
            if (self.hidden) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_HIDDEN_BOOLEAN, .{ .Boolean = val });
            if (self.high_pixel_density) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_HIGH_PIXEL_DENSITY_BOOLEAN, .{ .Boolean = val });
            if (self.maximized) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_MAXIMIZED_BOOLEAN, .{ .Boolean = val });
            if (self.menu) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_MENU_BOOLEAN, .{ .Boolean = val });
            if (self.metal) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_METAL_BOOLEAN, .{ .Boolean = val });
            if (self.minimized) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_MINIMIZED_BOOLEAN, .{ .Boolean = val });
            if (self.modal) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_MODAL_BOOLEAN, .{ .Boolean = val });
            if (self.mouse_grabbed) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_MOUSE_GRABBED_BOOLEAN, .{ .Boolean = val });
            if (self.open_gl) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_OPENGL_BOOLEAN, .{ .Boolean = val });
            if (self.parent) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_PARENT_POINTER, .{ .Pointer = val.value });
            if (self.resizable) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_RESIZABLE_BOOLEAN, .{ .Boolean = val });
            if (self.title) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_TITLE_STRING, .{ .String = val });
            if (self.transparent) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_TRANSPARENT_BOOLEAN, .{ .Boolean = val });
            if (self.tooltip) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_TOOLTIP_BOOLEAN, .{ .Boolean = val });
            if (self.utility) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_UTILITY_BOOLEAN, .{ .Boolean = val });
            if (self.vulkan) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_VULKAN_BOOLEAN, .{ .Boolean = val });
            if (self.width) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WIDTH_NUMBER, .{ .Number = @intCast(val) });
            if (self.x) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_X_NUMBER, .{ .Number = @intCast(val.toSdl()) });
            if (self.y) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_Y_NUMBER, .{ .Number = @intCast(val.toSdl()) });
            if (self.cocoa_window) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_COCOA_WINDOW_POINTER, .{ .Pointer = val });
            if (self.cocoa_view) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_COCOA_VIEW_POINTER, .{ .Pointer = val });
            if (self.wayland_surface_role_custom) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WAYLAND_SURFACE_ROLE_CUSTOM_BOOLEAN, .{ .Boolean = val });
            if (self.wayland_create_egl_window) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WAYLAND_CREATE_EGL_WINDOW_BOOLEAN, .{ .Boolean = val });
            if (self.wayland_create_wl_surface) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WAYLAND_WL_SURFACE_POINTER, .{ .Pointer = val });
            if (self.win32_hwnd) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WIN32_HWND_POINTER, .{ .Pointer = val });
            if (self.win32_pixel_format_hwnd) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_WIN32_PIXEL_FORMAT_HWND_POINTER, .{ .Pointer = val });
            if (self.x11_window) |val|
                ret.set(C.SDL_PROP_WINDOW_CREATE_X11_WINDOW_NUMBER, .{ .Number = @intCast(val) });
            return ret;
        }
    };

    /// Position of a window.
    ///
    /// ## Version
    /// This union is provided without zig-sdl3.
    pub const Position = union(enum) {
        /// Specify the absolute position of the window.
        absolute: i32,
        /// Center the window on the display.
        centered: void,
        /// Put the window wherever I guess.
        undefined: void,

        /// Convert to the SDL representation.
        pub fn toSdl(
            self: Position,
        ) c_int {
            return switch (self) {
                .absolute => |val| @intCast(val),
                .centered => C.SDL_WINDOWPOS_CENTERED,
                .undefined => C.SDL_WINDOWPOS_UNDEFINED,
            };
        }
    };

    /// Create a child popup window of the specified parent window.
    ///
    /// ## Function Parameters
    /// * `self`: Parent window to make a popup for.
    /// * `offset_x`: The x position of the popup window relative to the origin of the parent.
    /// * `offset_y`: The y position of the popup window relative to the origin of the parent.
    /// * `width`: The width of the window.
    /// * `height`: The height of the window.
    /// * `flags`: Window flags that must contain `tooltip` or `popup_menu`.
    ///
    /// ## Return Value
    /// Returns the window created.
    ///
    /// ## Remarks
    /// The flags parameter must contain at least one of the following:
    /// * `tooltip`: The popup window is a tooltip and will not pass any input events.
    /// * `popup_menu`: The popup window is a popup menu. The topmost popup menu will implicitly gain the keyboard focus.
    ///
    /// The following flags are not relevant to popup window creation and will be ignored:
    /// * `minimized`
    /// * `maximized`
    /// * `fullscreen`
    /// * `borderless`
    ///
    /// The following flags are incompatible with popup window creation and will cause it to fail:
    /// * `utility`
    /// * `modal`
    ///
    /// The parent of a popup window can be either a regular, toplevel window, or another popup window.
    ///
    /// Popup windows cannot be minimized, maximized, made fullscreen, raised, flash, be made a modal window,
    /// be the parent of a toplevel window, or grab the mouse and/or keyboard.
    /// Attempts to do so will fail.
    ///
    /// Popup windows implicitly do not have a border/decorations and do not appear on the taskbar/dock or in lists
    /// of windows such as alt-tab menus.
    ///
    /// If a parent window is hidden or destroyed, any child popup windows will be recursively hidden or destroyed as well.
    /// Child popup windows not explicitly hidden will be restored when the parent is shown.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn createPopup(
        self: Window,
        offset_x: i32,
        offset_y: i32,
        width: u32,
        height: u32,
        flags: WindowFlags,
    ) !Window {
        const ret = C.SDL_CreatePopupWindow(
            self.value,
            @intCast(offset_x),
            @intCast(offset_y),
            @intCast(width),
            @intCast(height),
            flags.toSdl(),
        );
        return .{
            .value = try errors.wrapNull(*C.SDL_Window, ret),
        };
    }

    /// Destroy a window.
    ///
    /// ## Function Parameters
    /// * `self`: The window to destroy.
    ///
    /// ## Remarks
    /// Any child windows owned by the window will be recursively destroyed as well.
    ///
    /// Note that on some platforms, the visible window may not actually be removed from the screen until the SDL event loop is pumped again,
    /// even though the `video.Window` is no longer valid after this call.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn deinit(
        self: Window,
    ) void {
        C.SDL_DestroyWindow(
            self.value,
        );
    }

    /// Destroy the surface associated with the window.
    ///
    /// ## Function Parameters
    /// * `self`: The window to update.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn destroySurface(
        self: Window,
    ) !void {
        const ret = C.SDL_DestroyWindowSurface(self.value);
        return errors.wrapCallBool(ret);
    }

    /// Request a window to demand attention from the user.
    ///
    /// ## Function parameters
    /// * `self`: The window to be flashed.
    /// * `operation`: The operation to perform.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn flash(
        self: Window,
        operation: FlashOperation,
    ) !void {
        const ret = C.SDL_FlashWindow(self.value, operation.toSdl());
        return errors.wrapCallBool(ret);
    }

    /// Create a window with the specified dimensions and flags.
    ///
    /// ## Function Parameters
    /// * `title`: The title of the window, in UTF-8 encoding.
    /// * `width`: The width of the window.
    /// * `height`: The height of the window.
    /// * `flags`: Window flags.
    ///
    /// ## Return Value
    /// Returns the window that was created.
    ///
    /// ## Remarks
    /// The window is implicitly shown if `video.Window.WindowFlags.hidden` is not set.
    ///
    /// On Apple's macOS, you must set the `NSHighResolutionCapable` `Info.plist` property to `YES`,
    /// otherwise you will not receive a High-DPI OpenGL canvas.
    ///
    /// The window pixel size may differ from its window coordinate size if the window is on a high pixel density display.
    /// Use `video.Window.getSize()` to query the client area's size in window coordinates,
    /// and `video.Window.getSizeInPixels()` or `renderer.Renderer.getOutputSize()` to query the drawable size in pixels.
    /// Note that the drawable size can vary after the window is created and should be queried again
    /// if you get a `event.Window.pixel_size_changed` event.
    ///
    /// If the window is created with any of the `video.Window.WindowFlags.open_gl` or `video.Window.WindowFlags.vulkan` flags,
    /// then the corresponding LoadLibrary function (`video.gl_load_library()` or `video.vulkan_load_library()`) is called
    /// and the corresponding UnloadLibrary function is called by `video.Window.deinit()`.
    ///
    /// If `video.Window.WindowFlags.vulkan` is specified and there isn't a working Vulkan driver, `video.Window.init()` will fail,
    /// because `video.vulkan_load_library()` will fail.
    ///
    /// If `video.Window.WindowFlags.metal` is specified on an OS that does not support Metal, `video.Window.init()` will fail.
    ///
    /// If you intend to use this window with a `renderer.Renderer`,
    /// you should use `renderer.Render.initWithWindow()` instead of this function, to avoid window flicker.
    ///
    /// On non-Apple devices, SDL requires you to either not link to the Vulkan loader or link to a dynamic library version.
    /// This limitation may be removed in a future version of SDL.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// ```zig
    /// const std = @import("std");
    /// const sdl3 = @import("sdl3");
    ///
    /// const SCREEN_WIDTH = 640;
    /// const SCREEN_HEIGHT = 480;
    ///
    /// pub fn main() !void {
    ///     defer sdl3.init.shutdown();
    ///
    ///     const init_flags = sdl3.init.Flags{ .video = true };
    ///     try sdl3.init.init(init_flags);
    ///     defer sdl3.init.quit(init_flags);
    ///
    ///     const window = try sdl3.video.Window.init("Hello SDL3", SCREEN_WIDTH, SCREEN_HEIGHT, .{});
    ///     defer window.deinit();
    ///
    ///     const surface = try window.getSurface();
    ///     try surface.fillRect(null, surface.mapRgb(128, 30, 255));
    ///     try window.updateSurface();
    ///
    ///     sdl3.timer.delayMilliseconds(5000);
    /// }
    /// ```
    ///
    /// TODO: Switch to example that also shows handling events!!!
    pub fn init(
        title: [:0]const u8,
        width: u32,
        height: u32,
        flags: WindowFlags,
    ) !Window {
        const ret = C.SDL_CreateWindow(
            title,
            @intCast(width),
            @intCast(height),
            flags.toSdl(),
        );
        return .{
            .value = try errors.wrapNull(*C.SDL_Window, ret),
        };
    }

    /// Create a window with the specified properties.
    ///
    /// ## Function Parameters
    /// * `props`: The properties to use.
    ///
    /// ## Return Value
    /// Returns the window that was created along with a properties group that you must free with `properties.Group.deinit()`.
    ///
    /// ## Remarks
    /// The window is implicitly shown if the "hidden" property is not set.
    ///
    /// Windows with the "tooltip" and "menu" properties are popup windows and have the behaviors and guidelines outlined in `video.Window.createPopup()`.
    ///
    /// If this window is being created to be used with a `video.Renderer`, you should not add a graphics API specific property (`video.Window.CreateProperites.open_gl`, etc),
    /// as SDL will handle that internally when it chooses a renderer.
    /// However, SDL might need to recreate your window at that point, which may cause the window to appear briefly, and then flicker as it is recreated.
    /// The correct approach to this is to create the window with the `video.Window.CreateProperites.hidden` property set to true, then create the renderer,
    /// then show the window with `video.Window.show()`.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    ///
    /// ## Code Examples
    /// TODO: ADD EXAMPLE!!!
    pub fn initWithProperties(
        props: CreateProperties,
    ) !struct { window: Window, properties: properties.Group } {
        const group = try props.toProperties();
        errdefer group.deinit();

        const window = try errors.wrapNull(*C.SDL_Window, C.SDL_CreateWindowWithProperties(group.value));
        return .{ .window = window, .properties = group };
    }

    /// Get the window that currently has an input grab enabled.
    ///
    /// ## Return Value
    /// Returns the window if input is grabbed or `null` otherwise.
    ///
    /// ## Thread Safety
    /// This function should only be called on the main thread.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getGrabbed() ?Window {
        return .{ .value = C.SDL_GetGrabbedWindow() orelse return null };
    }

    /// Get the SDL surface associated with the window.
    pub fn getSurface(
        self: Window,
    ) !surface.Surface {
        const ret = C.SDL_GetWindowSurface(
            self.value,
        );
        if (ret == null)
            return error.SdlError;
        return surface.Surface{ .value = ret };
    }

    /// Copy the window surface to the screen.
    pub fn updateSurface(
        self: Window,
    ) !void {
        const ret = C.SDL_UpdateWindowSurface(
            self.value,
        );
        if (!ret)
            return error.SdlError;
    }

    /// Confines the cursor to the specified area of a window.
    pub fn setMouseRect(
        self: Window,
        area: ?rect.IRect,
    ) !void {
        const area_sdl: ?C.SDL_Rect = if (area == null) null else area.?.toSdl();
        const ret = C.SDL_SetWindowMouseRect(
            self.value,
            if (area_sdl == null) null else &(area_sdl.?),
        );
        if (!ret)
            return error.SdlError;
    }
};

/// The flags on a window.
///
/// ## Remarks
/// These cover a lot of true/false, or on/off, window state.
/// Some of it is immutable after being set through `video.Window.init()`,
/// some of it can be changed on existing windows by the app,
/// and some of it might be altered by the user or system outside of the app's control.
///
/// ## Version
/// This datatype is available since SDL 3.2.0.
pub const WindowFlags = struct {
    /// Window is in fullscreen mode.
    fullscreen: bool = false,
    /// Window usable with OpenGL context.
    open_gl: bool = false,
    /// Window is occluded.
    occluded: bool = false,
    /// Window is neither mapped onto the desktop nor shown in the taskbar/dock/window list.
    /// The `video.Window.show()` function must be called for the window.
    hidden: bool = false,
    /// No window decoration.
    borderless: bool = false,
    /// Window can be resized.
    resizable: bool = false,
    /// Window is minimized.
    minimized: bool = false,
    /// Window is maximized.
    maximized: bool = false,
    /// Window has grabbed mouse input.
    mouse_grabbed: bool = false,
    /// Window has input focus.
    input_focus: bool = false,
    /// Window has mouse focus.
    mouse_focus: bool = false,
    /// Window not created by SDL.
    external: bool = false,
    /// Window is modal.
    modal: bool = false,
    /// Window uses high pixel density back buffer if possible.
    high_pixel_density: bool = false,
    /// Window has mouse captured (unrelated to `video.WindowFlags.mouse_grabbed`)
    mouse_capture: bool = false,
    /// Window has relative mode enabled.
    mouse_relative_mode: bool = false,
    /// Window should always be above others.
    always_on_top: bool = false,
    /// Window should be treated as a utility window, not showing in the task bar and window list.
    utility: bool = false,
    /// Window should be treated as a tooltip and does not get mouse or keyboard focus, requires a parent window.
    tooltip: bool = false,
    /// Window should be treated as a popup menu, requires a parent window.
    popup_menu: bool = false,
    /// Window has grabbed keyboard input.
    keyboard_grabbed: bool = false,
    /// Window usable for Vulkan surface.
    vulkan: bool = false,
    /// Window usable for Metal view.
    metal: bool = false,
    /// Window with transparent buffer.
    transparent: bool = false,
    /// Window should not be focusable.
    not_focusable: bool = false,

    /// Convert from an SDL value.
    pub fn fromSdl(flags: C.SDL_WindowFlags) WindowFlags {
        return .{
            .fullscreen = (flags & C.SDL_WINDOW_FULLSCREEN) != 0,
            .open_gl = (flags & C.SDL_WINDOW_OPENGL) != 0,
            .occluded = (flags & C.SDL_WINDOW_OCCLUDED) != 0,
            .hidden = (flags & C.SDL_WINDOW_HIDDEN) != 0,
            .borderless = (flags & C.SDL_WINDOW_BORDERLESS) != 0,
            .resizable = (flags & C.SDL_WINDOW_RESIZABLE) != 0,
            .minimized = (flags & C.SDL_WINDOW_MINIMIZED) != 0,
            .maximized = (flags & C.SDL_WINDOW_MAXIMIZED) != 0,
            .mouse_grabbed = (flags & C.SDL_WINDOW_MOUSE_GRABBED) != 0,
            .input_focus = (flags & C.SDL_WINDOW_INPUT_FOCUS) != 0,
            .mouse_focus = (flags & C.SDL_WINDOW_MOUSE_FOCUS) != 0,
            .external = (flags & C.SDL_WINDOW_EXTERNAL) != 0,
            .modal = (flags & C.SDL_WINDOW_MODAL) != 0,
            .high_pixel_density = (flags & C.SDL_WINDOW_HIGH_PIXEL_DENSITY) != 0,
            .mouse_capture = (flags & C.SDL_WINDOW_MOUSE_CAPTURE) != 0,
            .mouse_relative_mode = (flags & C.SDL_WINDOW_MOUSE_RELATIVE_MODE) != 0,
            .always_on_top = (flags & C.SDL_WINDOW_ALWAYS_ON_TOP) != 0,
            .utility = (flags & C.SDL_WINDOW_UTILITY) != 0,
            .tooltip = (flags & C.SDL_WINDOW_TOOLTIP) != 0,
            .popup_menu = (flags & C.SDL_WINDOW_POPUP_MENU) != 0,
            .keyboard_grabbed = (flags & C.SDL_WINDOW_KEYBOARD_GRABBED) != 0,
            .vulkan = (flags & C.SDL_WINDOW_VULKAN) != 0,
            .metal = (flags & C.SDL_WINDOW_METAL) != 0,
            .transparent = (flags & C.SDL_WINDOW_TRANSPARENT) != 0,
            .not_focusable = (flags & C.SDL_WINDOW_NOT_FOCUSABLE) != 0,
        };
    }

    /// Convert to an SDL value.
    pub fn toSdl(self: WindowFlags) C.SDL_WindowFlags {
        return (if (self.fullscreen) @as(C.SDL_WindowFlags, C.SDL_WINDOW_FULLSCREEN) else 0) |
            (if (self.open_gl) @as(C.SDL_WindowFlags, C.SDL_WINDOW_OPENGL) else 0) |
            (if (self.occluded) @as(C.SDL_WindowFlags, C.SDL_WINDOW_OCCLUDED) else 0) |
            (if (self.hidden) @as(C.SDL_WindowFlags, C.SDL_WINDOW_HIDDEN) else 0) |
            (if (self.borderless) @as(C.SDL_WindowFlags, C.SDL_WINDOW_BORDERLESS) else 0) |
            (if (self.resizable) @as(C.SDL_WindowFlags, C.SDL_WINDOW_RESIZABLE) else 0) |
            (if (self.minimized) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MINIMIZED) else 0) |
            (if (self.maximized) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MAXIMIZED) else 0) |
            (if (self.mouse_grabbed) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MOUSE_GRABBED) else 0) |
            (if (self.input_focus) @as(C.SDL_WindowFlags, C.SDL_WINDOW_INPUT_FOCUS) else 0) |
            (if (self.mouse_focus) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MOUSE_FOCUS) else 0) |
            (if (self.external) @as(C.SDL_WindowFlags, C.SDL_WINDOW_EXTERNAL) else 0) |
            (if (self.modal) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MODAL) else 0) |
            (if (self.high_pixel_density) @as(C.SDL_WindowFlags, C.SDL_WINDOW_HIGH_PIXEL_DENSITY) else 0) |
            (if (self.mouse_capture) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MOUSE_CAPTURE) else 0) |
            (if (self.mouse_relative_mode) @as(C.SDL_WindowFlags, C.SDL_WINDOW_MOUSE_RELATIVE_MODE) else 0) |
            (if (self.always_on_top) @as(C.SDL_WindowFlags, C.SDL_WINDOW_ALWAYS_ON_TOP) else 0) |
            (if (self.utility) @as(C.SDL_WindowFlags, C.SDL_WINDOW_UTILITY) else 0) |
            (if (self.tooltip) @as(C.SDL_WindowFlags, C.SDL_WINDOW_TOOLTIP) else 0) |
            (if (self.popup_menu) @as(C.SDL_WindowFlags, C.SDL_WINDOW_POPUP_MENU) else 0) |
            (if (self.keyboard_grabbed) @as(C.SDL_WindowFlags, C.SDL_WINDOW_KEYBOARD_GRABBED) else 0) |
            (if (self.vulkan) @as(C.SDL_WindowFlags, C.SDL_WINDOW_VULKAN) else 0) |
            (if (self.metal) @as(C.SDL_WindowFlags, C.SDL_WINDOW_METAL) else 0) |
            (if (self.transparent) @as(C.SDL_WindowFlags, C.SDL_WINDOW_TRANSPARENT) else 0) |
            (if (self.not_focusable) @as(C.SDL_WindowFlags, C.SDL_WINDOW_NOT_FOCUSABLE) else 0) |
            0;
    }
};

/// Prevent the screen from being blanked by a screen saver.
///
/// ## Remarks
/// If you disable the screensaver, it is automatically re-enabled when SDL quits.
///
/// The screensaver is disabled by default, but this may by changed by `hints.Type.allow_screensaver`.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn disableScreenSaver() !void {
    const ret = C.SDL_DisableScreenSaver();
    return errors.wrapCallBool(ret);
}

/// Allow the screen to be blanked by a screen saver.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn enableScreenSaver() !void {
    const ret = C.SDL_EnableScreenSaver();
    return errors.wrapCallBool(ret);
}

/// Get the name of the currently initialized video driver.
///
/// ## Return Value
/// Returns the name of the current video driver or `null` if no driver has been initialized.
///
/// ## Remarks
/// The names of drivers are all simple, low-ASCII identifiers, like "cocoa", "x11" or "windows".
/// These never have Unicode characters, and are not meant to be proper names.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getCurrentDriverName() ?[]const u8 {
    const ret = C.SDL_GetCurrentVideoDriver();
    if (ret) |val|
        return std.mem.span(val);
    return null;
}

/// Get the display containing a point.
///
/// ## Function Parameters
/// * `point`: The point to query.
///
/// ## Return Value
/// Returns the display containing the point.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getDisplayForPoint(point: rect.IPoint) !Display {
    const c_point = point.toSdl();
    const ret = C.SDL_GetDisplayForPoint(&c_point);
    return .{ .value = try errors.wrapCall(C.SDL_DisplayID, ret, 0) };
}

/// Get the display primarily containing a rect.
///
/// ## Function Parameters
/// * `space`: The rect to query.
///
/// ## Return Value
/// Returns the display containing the rect.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getDisplayForRect(space: rect.IRect) !Display {
    const c_rect = space.toSdl();
    const ret = C.SDL_GetDisplayForRect(&c_rect);
    return .{ .value = try errors.wrapCall(C.SDL_DisplayID, ret, 0) };
}

/// Get the display associated with a window.
///
/// ## Function Parameters
/// * `window`: The window to query.
///
/// ## Return Value
/// Returns the display containing the center of the window.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
///
/// ## Code Examples
/// TODO!!!
pub fn getDisplayForWindow(window: Window) !Display {
    const ret = C.SDL_GetDisplayForWindow(window.value);
    return .{ .value = try errors.wrapCall(C.SDL_DisplayID, ret, 0) };
}

/// Get the number of video drivers compiled into SDL.
///
/// ## Return Value
/// Returns the number of built in video drivers.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getNumDrivers() usize {
    const ret = C.SDL_GetNumVideoDrivers();
    return @intCast(ret);
}

/// Get the current system theme.
///
/// ## Return Value
/// Returns the current system theme, light, dark, or unknown.
///
/// ## Thread Safety
/// This function should only be called on the main thread.
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub fn getSystemTheme() ?SystemTheme {
    const ret = C.SDL_GetSystemTheme();
    if (ret == C.SDL_SYSTEM_THEME_UNKNOWN)
        return null;
    return @enumFromInt(ret);
}

/// Get the name of a built in video driver.
pub fn getDriverName(
    index: u31,
) ?[]const u8 {
    const ret = C.SDL_GetVideoDriver(
        @intCast(index),
    );
    if (ret == null)
        return null;
    return std.mem.span(ret);
}

// Tests for the video subsystem.
test "Video" {
    // Window.createPopup
    // Window.init
    // Window.initWithProperties
    // Window.deinit
    // Window.destroySurface
    // disableScreensaver
    // egl.getCurrentConfig
    // egl.getCurrentDisplay
    // egl.getProcAddress
    // egl.getWindowSurface
    // egl.setAttributeCallbacks
    // enableScreenSaver
    // Window.flash
    // Display.getClosestFullscreenMode
    // Display.getCurrentMode
    // Display.getCurrentOrientation
    // getCurrentDriverName
    // Display.getDesktopMode
    // Display.getBounds
    // getDisplayForPoint
    // getDisplayForRect
    // getDisplayForWindow
    // Display.getName
    // Display.getProperties
    // Display.getAll
    // Display.getUsableBounds
    // Display.getFullscreenModes
    // Window.getGrabbed
    // Display.getNaturalOrientation
    // getNumDrivers
    // Display.getPrimaryDisplay
    // getSystemTheme
    // getVideoDriver
}
