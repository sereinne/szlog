//! [see](https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797)
//! Later, if possible, will redesign into an interface.

const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

/// Options for `EightBit` and 16-bit colors.
pub const EtoSOptions = struct {
    /// Sets mode of text.
    mode: u4,
    /// Sets foreground of text.
    fg: u8,
    /// Sets background of text.
    bg: u8,
};

/// Options for `Extended`.
pub const ExtendedOptions = struct {
    /// Sets foreground of text based on ID (0-255).
    fg_id: u8,
    /// Sets background of text based on ID (0-255).
    bg_id: u8,
};

/// Options for `Rgb`.
pub const RgbOptions = struct {
    /// Sets red foreground of text range from 0 to 255.
    r_fg: u8,
    /// Sets green foreground of text range from 0 to 255.
    g_fg: u8,
    /// Sets blue foreground of text range from 0 to 255.
    b_fg: u8,
    /// Sets red background of text range from 0 to 255.
    r_bg: u8,
    /// Sets green background of text range from 0 to 255.
    g_bg: u8,
    /// Sets blue background of text range from 0 to 255.
    b_bg: u8,
};

/// A struct that is only a namespace for the implementation of `EightBit` `colorizer` function.
pub const EightBit = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: EtoSOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[{d};{d};{d}m{s}\x1b[0m", .{ opts.mode, opts.fg, opts.bg, text });
        return result;
    }
};

/// A struct that is only a namespace for the implementation of `Extended` `colorizer` function.
pub const Extended = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: ExtendedOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[38;5;{d};48;5;{d}m{s}\x1b[0m", .{ opts.fg_id, opts.bg_id, text });
        return result;
    }
};

/// A struct that is only a namespace for the implementation of `Rgb` `colorizer` function.
pub const Rgb = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: RgbOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[38;2;{d};{d};{d};48;2;{d};{d};{d}m{s}\x1b[0m", .{ opts.r_fg, opts.g_fg, opts.b_fg, opts.r_bg, opts.g_bg, opts.b_bg, text });
        return result;
    }
};

/// All possible types of colorizing functions.
pub const Colorizer = union(enum) {
    eightbit: EtoSOptions,
    sixteenbit: EtoSOptions,
    extended: ExtendedOptions,
    rgb: RgbOptions,

    /// Colorize text based on an active union variant.
    pub fn colorize(self: Colorizer, comptime text: []const u8) []const u8 {
        return switch (self) {
            .eightbit, .sixteenbit => |opts| {
                return EightBit.colorizer(text, opts);
            },
            .extended => |opts| {
                return Extended.colorizer(text, opts);
            },
            .rgb => |opts| {
                return Rgb.colorizer(text, opts);
            },
        };
    }
};
