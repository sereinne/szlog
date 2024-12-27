// API blueprint.
// const opts = LoggerOpts {
//      output: stdout, stderr, logfile, (either one)
//      format: text, json (either one)
//      color: stdascii, brightascii, extendedascii, rgb (option),
//      timestamp: bool (false),
//      level: Level (lowest level in order to log all levels including the lowest to the highest),
// };
// var logger = Logger.default(); or Logger.new(opts);
// first param: main message
// second param: kv pairs with the key must be a string and the value can be anything
// also the there can be a key that has no value (empty key) which is assign value as `null`
// logger.log("Hello, World", .{"foo", "bar", "baz", 1, "empty_key"})
//
// external references: https://gist.github.com/fnky/458719343aabd01cfb17a3a4f7296797

const std = @import("std");
const File = std.fs.File;
const comptimePrint = std.fmt.comptimePrint;

/// All supported types of output where logs messages gets into.
const Output = union(enum) {
    /// Output gets in into stdout.
    Stdout,
    /// Output gets in into stderr.
    Stderr,
    /// Output gets in into a logfile that the user must create first.
    Logfile: File,
};

/// All supported types of log format options for Szlog.
const Format = union(enum) {
    /// No format (basically simple key-value pair).
    Text,
    /// format based on JSON specification.
    Json,
};

const StdColor = struct {
    const Self = @This();

    mode: u4,
    fg: u8,
    bg: u8,

    pub fn color_text(self: *const Self, text: []const u8) []const u8 {
        return comptimePrint("\x1b[{d};{d};{d}m{s}\x1b[0m", .{ self.mode, self.fg, self.bg, text });
    }
};

const ExtColor = struct {
    const Self = @This();
    // this fits well because all possible id is 0-255 range.
    fg_id: u8,
    bg_id: u8,

    pub fn color_text(self: *const Self, text: []const u8) []const u8 {
        return comptimePrint("\x1b[38;5;{d};48;5;{d}m{s}\x1b[0m", .{ self.fg_id, self.bg_id, text });
    }
};

const RgbColor = struct {
    const Self = @This();

    red_fg: u8,
    green_fg: u8,
    blue_fg: u8,
    red_bg: u8,
    green_bg: u8,
    blue_bg: u8,

    pub fn color_text(self: *const Self, text: []const u8) []const u8 {
        return comptimePrint("\x1b[38;2;{d};{d};{d};48;2;{d};{d};{d}m{s}\x1b[0m", .{ self.red_fg, self.green_fg, self.blue_fg, self.red_bg, self.green_bg, self.blue_bg, text });
    }
};

/// All supported types of color rendering in a TTY (terminal).
const ColorType = union(enum) {
    const Self = @This();
    /// 8 color mode.
    // format: "\x1b[<mode>;<fg>;<bg>m".
    // note that bg is 10 units more than fg.
    StdASCII: StdColor,
    /// 16 color mode.
    // format: "\x1b[<mode>;<fg or bg>m".
    // note that bg is 10 units more than fg.
    BrightASCII: StdColor,
    /// 256 color mode.
    // format: "\x1b[38;5;{ID}m" for foreground.
    // format: "\x1b[48;5;{ID}m" for background.
    // format: (for both in one line) "\x1b[38;5;{ID};48;5;{ID}m"
    // where ID has a range of 0-255 (u8 is sufficient).
    ExtASCII: ExtColor,
    /// RGB color mode.
    // format: "\x1b[38;2;{red};{green};{blue}m" for foreground
    // format: "\x1b[48;2;{red};{green};{blue}m" for background
    // format: (for both in one line) "\x1b[38;2;{red};{green};{blue};48;2;{red};{green};{blue}m"
    Rgb: RgbColor,
};
const Timestamp = union(enum) {
    /// Data.
    Date,
    /// Time.
    Time,
    /// Both Date and Time.
    Both,
};

/// All supported types of log levels. if a level has been set, then Szlog will log higher or equal than that level.
const Level = enum(u4) {
    trace = 0,
    debug = 1,
    info = 2,
    warning = 3,
    @"error" = 4,
    panic = 5,
};

/// All supported options for Szlog.
pub const SzlogConfig = struct {
    output: Output,
    format: Format,
    color: ?ColorType = null,
    timestamp: Timestamp,
    level: Level,
};

/// Logger to use.
pub const Szlog = struct {
    const Self = @This();
    /// Options passed before use.
    config: SzlogConfig,

    /// Initialize logger based on available configuration options.
    pub fn new(config: SzlogConfig) Self {
        return Self{
            .config = config,
        };
    }

    /// Initialize logger using default configuration options.
    pub fn default() Self {
        const config = SzlogConfig{
            .output = .Stdout,
            .format = .Text,
            .color = null,
            .timestamp = .Both,
            .level = .info,
        };
        return Self{
            .config = config,
        };
    }

    /// logs `Format`ed with `Color` and `Timestamp` messages into `Output` with a log `Level`.
    /// `msg` is any message.
    /// `args` is a tuple of key-value pairs with a key that has a type string and value that has any type.
    pub fn log(self: *Self, msg: []const u8, args: anytype) void {
        switch (self.config.format) {
            .Text => {
                self.printToOutputText(msg, args);
            },
            .Json => {
                self.printToOutputJson(msg, args);
            },
        }
    }

    // Helper function to catch error (doesnt handle it gracefully).
    fn catchErr(e: anyerror) noreturn {
        std.debug.panic("PANIC: {s}\n", .{@errorName(e)});
    }

    // check is an item is a []const u8 or *const [N:0]u8
    fn isStringType(item: anytype) bool {
        return isStringSlice(item) or isStaticStr(item);
    }

    // check if an item is []const u8
    fn isStringSlice(item: anytype) bool {
        const T = @TypeOf(item);
        const info = @typeInfo(T);

        if (info != .Pointer) {
            return false;
        }

        if (info.Pointer.size != .Slice or !info.Pointer.is_const or info.Pointer.child != u8) {
            return false;
        }

        return true;
    }

    // check if an item is *const [N:0]u8
    fn isStaticStr(item: anytype) bool {
        const T = @TypeOf(item);
        const info = @typeInfo(T);

        if (info != .Pointer) {
            return false;
        }

        if (!info.Pointer.is_const) {
            return false;
        }

        const child_info = @typeInfo(info.Pointer.child);

        if (child_info != .Array) {
            return false;
        }

        const length = child_info.Array.len;

        // Save to assume that child_info is an array.
        if (info.Pointer.size != .One or info.Pointer.child != [length:0]u8) {
            return false;
        }

        return true;
    }

    // Helper function to print text with no formatting.
    // prints final text with this order:
    // TODO: implement time conversion into daytime
    // 1. time
    // 2. level
    // 3. msg
    // 4. args
    fn printToOutputText(self: *Self, msg: []const u8, args: anytype) void {
        switch (self.config.output) {
            .Stdout => {
                const stdout = std.io.getStdOut();
                const writer = stdout.writer();
                const kvpair = self.convertArgsToStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("level={s} message={s} {s}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
            .Stderr => {
                const stderr = std.io.getStdErr();
                const writer = stderr.writer();
                const kvpair = self.convertArgsToStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("level={s} message={s} {s}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
            .Logfile => |logfile| {
                // whatever the value is, the color mode is disabled.
                if (self.config.color) |_| {
                    self.config.color = null;
                }
                const writer = logfile.writer();
                const kvpair = self.convertArgsToStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("level={s} message={s} {s}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
        }
    }

    // Helper function to print text with JSON format.
    // prints final text with this order:
    // 1. time
    // 2. level
    // 3. msg
    // 4. args
    fn printToOutputJson(self: *Self, msg: []const u8, args: anytype) void {
        switch (self.config.output) {
            .Stdout => {
                const stdout = std.io.getStdOut();
                const writer = stdout.writer();
                const kvpair = self.convertArgsToJsonStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("{{ \"level\": \"{s}\" \"message\": \"{s}\", {s} }}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
            .Stderr => {
                const stderr = std.io.getStdErr();
                const writer = stderr.writer();
                const kvpair = self.convertArgsToJsonStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("{{ \"level\": \"{s}\" \"message\": \"{s}\", {s} }}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
            .Logfile => |logfile| {
                if (self.config.color) |_| {
                    self.config.color = null;
                }
                const writer = logfile.writer();
                const kvpair = self.convertArgsToJsonStr(args);
                const log_level = @tagName(self.config.level);

                writer.print("{{ \"level\": \"{s}\" \"message\": \"{s}\", {s} }}", .{ log_level, msg, kvpair }) catch |err| catchErr(err);
            },
        }
    }

    // Returns convert `args` (tuple) into a key-value paired string.
    // the output can be colored if enabled.
    fn convertArgsToStr(self: *Self, args: anytype) []const u8 {
        comptime var result: []const u8 = "";
        inline for (args, 0..) |key, i| {
            // Check for type of `key`
            comptime {
                if (!isStringType(key) and i % 2 == 0) {
                    const T = @TypeOf(key);
                    const name = @typeName(T);
                    @compileError("key is " ++ name ++ " not a string!");
                }
            }

            // Check for colored output (only if it is enabled in `SzlogConfig` and is in a TTY)
            // does not need to check for if it is in a TTY because is it already checked at `printToOutputText`
            if (self.config.color) |color| {
                switch (color) {
                    .StdASCII => |cfg| {
                        _ = cfg; // autofix
                    },
                    .BrightASCII => |cfg| {
                        _ = cfg; // autofix
                    },
                    .ExtASCII => |cfg| {
                        _ = cfg; // autofix
                    },
                    .Rgb => |cfg| {
                        _ = cfg; // autofix
                    },
                }
            }

            // Check for out of bounds index
            if (i == args.len - 1) {
                // if `args.len` is odd, that means the last key doesn't have a value.
                if (args.len % 2 != 0) {
                    result = result ++ comptimePrint("{s}=null", .{key});
                    break;
                }
                break;
            }

            const value = args[i + 1];

            // this assumes that the key's index is always even and the value's index is always odd.
            comptime {
                if (!isStringType(value) and i % 2 == 0) {
                    result = result ++ comptimePrint("{s}={any} ", .{ key, value });
                } else if (i % 2 == 0) {
                    result = result ++ comptimePrint("{s}={s} ", .{ key, value });
                }
            }
        }
        return result;
    }

    // Returns convert `args` (tuple) into a JSON string (without outer brackets).
    // the output can be colored if enabled.
    fn convertArgsToJsonStr(self: *Self, args: anytype) []const u8 {
        comptime var result: []const u8 = "";
        inline for (args, 0..) |key, i| {
            comptime {
                if (!isStringType(key) and i % 2 == 0) {
                    const T = @TypeOf(key);
                    const name = @typeName(T);
                    @compileError("key is " ++ name ++ " not a string!");
                }
            }

            // Check for colored output (only if it is enabled in `SzlogConfig` and is in a TTY)
            // does not need to check for if it is in a TTY because is it already checked at `printToOutputJson`
            if (self.config.color) |color| {
                _ = color;
            }

            // the end of the argument.
            if (i == args.len - 1) {
                if (args.len % 2 != 0) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": null", .{key});
                    break;
                }
                break;
            }

            const value = args[i + 1];

            comptime {
                if (!isStringType(value) and i % 2 == 0 and i == args.len - 2) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": {any}", .{ key, value });
                } else if (i % 2 == 0 and i == args.len - 2) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": {s}", .{ key, value });
                } else if (!isStringType(value) and i % 2 == 0) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": {any}, ", .{ key, value });
                } else if (i % 2 == 0) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": {s}, ", .{ key, value });
                }
            }
        }
        return result;
    }
};

// playground
pub fn main() void {}
