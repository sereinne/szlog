const std = @import("std");
const color = @import("color.zig");
const Colorizer = color.Colorizer;

pub const TextFormatterOptions = struct {
    color: ?Colorizer,
};

pub const TextFormatter = struct {
    const Self = @This();
    opts: TextFormatterOptions,

    pub fn default() Self {
        return Self{ .opts = TextFormatterOptions{ .color = null } };
    }

    pub fn new(opts: TextFormatterOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    pub fn format_to_text(self: *const Self, comptime message: []const u8, args: anytype) []const u8 {
        _ = self;
        _ = args; // autofix
        comptime var result: []const u8 = "";
        result = result ++ "message=" ++ message;

        return result;
    }
};

pub const JsonFormatterOptions = struct {
    color: ?Colorizer,
};

pub const JsonFormatter = struct {
    const Self = @This();
    opts: JsonFormatterOptions,

    pub fn default() Self {
        return Self{ .opts = JsonFormatterOptions{ .color = null } };
    }

    pub fn new(opts: JsonFormatterOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    pub fn format_to_json(self: *const Self, comptime message: []const u8, args: anytype) []const u8 {
        _ = self;
        _ = args; // autofix
        comptime var result: []const u8 = "";
        result = result ++ "message=" ++ message;

        return result;
    }
};

pub const Formatter = union(enum) {
    const Self = @This();
    text: TextFormatter,
    json: JsonFormatter,

    pub fn format(self: Self, comptime message: []const u8, args: anytype) []const u8 {
        return switch (self) {
            .text => |fmt| {
                return fmt.format_to_text(message, args);
            },
            .json => |fmt| {
                return fmt.format_to_json(message, args);
            },
        };
    }
};
