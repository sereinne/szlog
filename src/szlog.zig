const std = @import("std");
const File = std.fs.File;

/// All types of possible output where the log message can go.
const Output = union(enum) {
    /// Logs into standard output.
    Stderr,
    /// Logs into standard error.
    Stdout,
    /// Logs into user defined log file.
    Logfile: File,
};

/// TODO: implement formatting for other than `Formatter.Text`.
const Formatter = union(enum) {
    /// One line key-value pair.
    Text,
    /// Logs into JSON format.
    Json,
};

/// Configuration options for the `Logger`.
pub const LoggerConfig = struct {
    output: Output,
    fmt: Formatter,
};

/// Structured logger with key-value pairs.
pub const Logger = struct {
    const Self = @This();

    config: LoggerConfig,

    /// Initialize logger with `LoggerConfig`.
    pub fn new(config: LoggerConfig) Self {
        return Self{
            .config = config,
        };
    }

    /// Initialize logger with default configurations.
    pub fn default() Self {
        const config = LoggerConfig{
            .output = .Stdout,
            .fmt = .Text,
        };
        return Self{
            .config = config,
        };
    }

    /// Logs message using structured logging.
    pub fn log(self: *Self, msg: []const u8, args: anytype) void {
        switch (self.config.fmt) {
            .Text => {
                self.printTextToOutput(msg, args);
            },
            .Json => {
                self.printJsonToOutput(msg, args);
            },
        }
    }

    // Helper function to handle errors with no message.
    fn handleErr(e: anyerror) noreturn {
        std.debug.panic("PANIC: {s}\n", .{@errorName(e)});
    }

    // Helper function to handle errors with a message.
    fn handleErrMsg(e: anyerror, msg: []const u8) noreturn {
        std.debug.panic("PANIC: {s}\n because of {s}\n", .{ @errorName(e), msg });
    }

    // Check for the type is a zig string ([]const u8 or *const [N:0]) or not
    pub fn isStringType(item: anytype) bool {
        return isStringSlice(item) or isStaticStr(item);
    }

    // Helper function to check for []const u8 type
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

    // Helper function to check for *const [N:0]u8
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

        // Save to assume that item is an array.
        if (info.Pointer.size != .One or info.Pointer.child != [length:0]u8) {
            return false;
        }

        return true;
    }

    // Helper function to turn a tuple into a formatted string.
    pub fn convertTupleToString(args: anytype) []const u8 {
        comptime var concatenated: []const u8 = "";
        inline for (args, 0..) |key, idx| {
            if (!isStringType(key)) {
                std.debug.panic("PANIC: key {any} is not a string!\n", .{key});
                break;
            }
            // Check for out of bounds index.
            if (idx == args.len - 1) {
                // If the arguments length is odd, that means there is a key that has no value.
                if (args.len % 2 != 0) {
                    concatenated = concatenated ++ std.fmt.comptimePrint("{s}=null ", .{key});
                    break;
                }
                break;
            }
            const value = args[idx + 1];
            // The key is always at the even index (starts at 0), meanwhile the value is always at the odd index (starts at 1).
            if (idx % 2 == 0) {
                concatenated = concatenated ++ std.fmt.comptimePrint("{s}={s} ", .{ key, value });
            }
        }
        return concatenated;
    }

    // Wrapper function to print (by text format) to each possible output in order to reduce duplication.
    fn printTextToOutput(self: *Self, msg: []const u8, args: anytype) void {
        // the first format string should be time .
        // the second format string should be `msg`.
        // the third format string should be `concatenated` (user args key value pairs).
        switch (self.config.output) {
            .Stdout => {
                const stdout = std.io.getStdOut();
                const stdout_writer = stdout.writer();
                const args_string = convertTupleToString(args);
                stdout_writer.print("{s} {s}", .{ msg, args_string }) catch |err| handleErr(err);
            },
            .Stderr => {
                const stderr = std.io.getStdErr();
                const stderr_writer = stderr.writer();
                const args_string = convertTupleToString(args);
                stderr_writer.print("{s} {s}", .{ msg, args_string }) catch |err| handleErr(err);
            },
            .Logfile => |file| {
                const writer = file.writer();
                const args_string = convertTupleToString(args);
                writer.print("{s} {s}", .{ msg, args_string }) catch |err| handleErr(err);
            },
        }
    }

    // Helper function to turn a tuple into a formatted JSON string.
    pub fn convertTupleToJSONString(args: anytype) []const u8 {
        // result contains only a JSON key value pair from args
        // it does not contains the final result.
        comptime var result: []const u8 = "";
        inline for (args, 0..) |key, idx| {
            if (!isStringType(key)) {
                std.debug.panic("PANIC: key {any} is not a string!\n", .{key});
                break;
            }

            // the end of the argument.
            if (idx == args.len - 1) {
                if (args.len % 2 != 0) {
                    result = result ++ std.fmt.comptimePrint("\"{s}\": null", .{key});
                    break;
                }
                break;
            }

            const value = args[idx + 1];

            if (idx % 2 == 0 and idx == args.len - 2) {
                result = result ++ std.fmt.comptimePrint("\"{s}\": {s}", .{ key, value });
                break;
            }

            // the index of each key is even, meanwhile the index of each value is odd.
            if (idx % 2 == 0) {
                result = result ++ std.fmt.comptimePrint("\"{s}\": {s}, ", .{ key, value });
            }
        }
        return result;
    }

    // TODO: implement how to print log messages using JSON format
    // Wrapper function to print (by JSON format) to each possible output in order to reduce duplication.
    // for now it will do the same as `printTextToOutput`.
    fn printJsonToOutput(self: *Self, msg: []const u8, args: anytype) void {
        // the first format string should be time .
        // the second format string should be `msg`.
        // the third format string should be `concatenated` (user args key value pairs).
        switch (self.config.output) {
            .Stdout => {
                const stdout = std.io.getStdOut();
                const stdout_writer = stdout.writer();
                const args_string = convertTupleToJSONString(args);
                stdout_writer.print("{{ \"message\": \"{s}\", {s} }}", .{ msg, args_string }) catch |err| handleErr(err);
            },
            .Stderr => {
                const stderr = std.io.getStdErr();
                const stderr_writer = stderr.writer();
                const args_string = convertTupleToJSONString(args);
                stderr_writer.print("{{ \"message\": \"{s}\", {s} }}", .{ msg, args_string }) catch |err| handleErr(err);
            },
            .Logfile => |file| {
                const writer = file.writer();
                const args_string = convertTupleToJSONString(args);
                writer.print("{{ \"message\": \"{s}\", {s} }}", .{ msg, args_string }) catch |err| handleErr(err);
            },
        }
    }
};

// playground to test
pub fn main() void {}
