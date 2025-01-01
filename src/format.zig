const std = @import("std");
const color = @import("color.zig");
const utils = @import("utils.zig");

const Colorizer = color.Colorizer;
const comptimePrint = std.fmt.comptimePrint;

pub const TextFormatterOptions = struct {
    quotes: bool,
};

pub const TextFormatter = struct {
    const Self = @This();
    opts: TextFormatterOptions,

    pub fn default() Self {
        return Self{ .opts = TextFormatterOptions{ .quotes = false } };
    }

    pub fn new(opts: TextFormatterOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    pub fn formatToText(self: *const Self, comptime message: []const u8, comptime clr: ?Colorizer, args: anytype) []const u8 {
        _ = self;
        comptime var result: []const u8 = "";
        const key_colored_msg = if (clr) |c| comptime c.colorize("message") else "message";
        result = result ++ comptimePrint("{s}={s} ", .{ key_colored_msg, message });
        result = result ++ comptime convertArgsToStr(args, clr);

        return result;
    }

    fn convertArgsToStr(args: anytype, comptime clr: ?Colorizer) []const u8 {
        comptime var result: []const u8 = "";
        inline for (args, 0..) |key, i| {
            // Check if `key` (in the even index) is a string.
            if (!utils.isStringType(key) and i % 2 == 0) {
                const T = @TypeOf(key);
                const name = @typeName(T);
                @compileError("Type: " ++ name ++ " is not a string type!");
            }

            const maybe_col_key = if (clr) |c| c.colorize(key) else key;

            // Look out for out of bounds index.
            if (i == args.len - 1) {
                // if the length of `args` is odd, the last `key` has not value.
                if (args.len % 2 != 0) {
                    result = result ++ comptimePrint("{s}=null", .{maybe_col_key});
                    break;
                }
                break;
            }

            const value = args[i + 1];

            // if the `value` can be represented as a string, it will use that rather than represented as `any`.
            if (utils.isStringType(value) and i % 2 == 0) {
                result = result ++ std.fmt.comptimePrint("{s}={s} ", .{ maybe_col_key, value });
            } else if (i % 2 == 0) {
                result = result ++ std.fmt.comptimePrint("{s}={any} ", .{ maybe_col_key, value });
            }
        }
        return result;
    }
};

pub const JsonFormatterOptions = struct {
    pretty: bool,
};

pub const JsonFormatter = struct {
    const Self = @This();
    opts: JsonFormatterOptions,

    pub fn default() Self {
        return Self{ .opts = JsonFormatterOptions{ .pretty = false } };
    }

    pub fn new(opts: JsonFormatterOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    pub fn formatToJson(self: *const Self, comptime message: []const u8, comptime clr: ?Colorizer, args: anytype) []const u8 {
        _ = self; // autofix
        comptime var result: []const u8 = "";
        const key_colored_msg = if (clr) |c| comptime c.colorize("message") else "message";
        result = result ++ comptimePrint("{{ \"{s}\": \"{s}\", ", .{ key_colored_msg, message });
        result = result ++ comptime convertToJsonStr(args, clr);

        return result;
    }

    pub fn convertToJsonStr(args: anytype, comptime clr: ?Colorizer) []const u8 {
        comptime var result: []const u8 = "";
        inline for (args, 0..) |key, i| {
            // Check if `key` (in the even index) is a string.
            if (!utils.isStringType(key) and i % 2 == 0) {
                const T = @TypeOf(key);
                const name = @typeName(T);
                @compileError("Type: " ++ name ++ " is not a string type!");
            }

            const maybe_col_keys = if (clr) |c| c.colorize(key) else key;

            // Look out for out of bounds index.
            if (i == args.len - 1) {
                // if the length of `args` is odd, the last `key` has not value.
                if (args.len % 2 != 0) {
                    result = result ++ comptimePrint("\"{s}\": null }}", .{maybe_col_keys});
                    break;
                }
                break;
            }

            const value = args[i + 1];

            // if the `value` can be represented as a string, it will use that rather than represented as `any`.
            if (utils.isStringType(value) and i % 2 == 0 and i == args.len - 2) {
                result = result ++ comptimePrint("\"{s}\": \"{s}\" }}", .{ maybe_col_keys, value });
            } else if (i % 2 == 0 and i == args.len - 2) {
                result = result ++ comptimePrint("\"{s}\": {any} }}", .{ maybe_col_keys, value });
            } else if (utils.isStringType(value) and i % 2 == 0) {
                result = result ++ comptimePrint("\"{s}\": {s}, ", .{ maybe_col_keys, value });
            } else if (i % 2 == 0) {
                result = result ++ comptimePrint("\"{s}\": {any}, ", .{ maybe_col_keys, value });
            }
        }
        return result;
    }
};

pub const Formatter = union(enum) {
    const Self = @This();
    text: TextFormatter,
    json: JsonFormatter,

    pub fn format(self: Self, comptime message: []const u8, comptime clr: ?Colorizer, args: anytype) []const u8 {
        return switch (self) {
            .text => |fmt| {
                return fmt.formatToText(message, clr, args);
            },
            .json => |fmt| {
                return fmt.formatToJson(message, clr, args);
            },
        };
    }
};
