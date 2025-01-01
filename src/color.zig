const std = @import("std");
const comptimePrint = std.fmt.comptimePrint;

pub const EtoSOptions = struct {
    mode: u4,
    fg: u8,
    bg: u8,
};

pub const ExtendedOptions = struct {
    fg_id: u8,
    bg_id: u8,
};

pub const RgbOptions = struct {
    r_fg: u8,
    g_fg: u8,
    b_fg: u8,
    r_bg: u8,
    g_bg: u8,
    b_bg: u8,
};

pub const EightBit = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: EtoSOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[{d};{d};{d}m{s}\x1b[0m", .{ opts.mode, opts.fg, opts.bg, text });
        return result;
    }
};

pub const Extended = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: ExtendedOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[38;5;{d};48;5;{d}m{s}\x1b[0m", .{ opts.fg_id, opts.bg_id, text });
        return result;
    }
};

pub const Rgb = struct {
    pub fn colorizer(comptime text: []const u8, comptime opts: RgbOptions) []const u8 {
        comptime var result: []const u8 = "";
        result = result ++ std.fmt.comptimePrint("\x1b[38;2;{d};{d};{d};48;2;{d};{d};{d}m{s}\x1b[0m", .{ opts.r_fg, opts.g_fg, opts.b_fg, opts.r_bg, opts.g_bg, opts.b_bg, text });
        return result;
    }
};

pub const Colorizer = union(enum) {
    eightbit: EtoSOptions,
    sixteenbit: EtoSOptions,
    extended: ExtendedOptions,
    rgb: RgbOptions,

    pub fn colorize(self: Colorizer, comptime text: []const u8) []const u8 {
        return switch (self) {
            .eightbit, .sixteenbit => |opts| {
                return EightBit.colorizer(text, opts);
            },
            .extended => |opts| {
                return Extended.colorizer(text, opts);
            },
        };
    }
};
