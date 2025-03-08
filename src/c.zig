pub const C = @cImport({
    @cInclude("SDL3/SDL.h");
    const ext_image = @import("extension_options").image; //optional include 
    if (ext_image) {
        @cInclude("SDL3_image/SDL_image.h");
    }
});
