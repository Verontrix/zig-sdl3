const C = @import("c.zig").C;
const stdinc = @import("stdinc.zig");

/// A struct to provide locale data.
///
/// ## Remarks
/// Locale data is split into a spoken language, like English, and an optional country, like Canada.
/// The language will be in ISO-639 format (so English would be "en"), and the country, if not `null`,
/// will be an ISO-3166 country code (so Canada would be "CA").
///
/// ## Version
/// This function is available since SDL 3.2.0.
pub const Locale = extern struct {
    /// A language name, like "en" for English.
    language: [*:0]const u8,
    /// A country, like "US" for America.
    /// Can be `null`.
    country: ?[*:0]const u8,

    /// Report the user's preferred locale.
    ///
    /// ## Return Value
    /// Returns a slice of preferred locales.
    /// This must be freed with `stdinc.free()`.
    ///
    /// ## Remarks
    /// Returned language strings are in the format xx, where 'xx' is an ISO-639 language specifier (such as "en" for English, "de" for German, etc).
    /// Country strings are in the format YY, where "YY" is an ISO-3166 country code (such as "US" for the United States, "CA" for Canada, etc).
    /// Country might be `null` if there's no specific guidance on them (so you might get { "en", "US" } for American English,
    /// but { "en", `null` } means "English language, generically").
    ///
    /// Please note that not all of these strings are 2 characters; some are three or more.
    ///
    /// The returned list of locales are in the order of the user's preference.
    /// For example, a German citizen that is fluent in US English and knows enough Japanese to
    /// navigate around Tokyo might have a list like: { "de", "en_US", "jp", NULL }.
    /// Someone from England might prefer British English (where "color" is spelled "colour", etc),
    /// but will settle for anything like it: { "en_GB", "en", NULL }.
    ///
    /// This might be a "slow" call that has to query the operating system.
    /// It's best to ask for this once and save the results.
    /// However, this list can change, usually because the user has changed a system preference outside of your program;
    /// SDL will send an `event.locale_changed` event in this case, if possible, and you can call this function again to get an updated copy of preferred locales.
    ///
    /// ## Version
    /// This function is available since SDL 3.2.0.
    pub fn getPreferred() ![]*Locale {
        var cnt: c_int = undefined;
        const ret: [*]*Locale = @ptrCast(C.SDL_GetPreferredLocales(&cnt));
        return ret[0..@intCast(cnt)];
    }
};

// Test fetching locale.
test "Locale" {
    const locales = Locale.getPreferred() catch return;
    defer stdinc.free(locales);
}
