const std = @import("std");

/// All types of possible output where the log message can go.
const Output = union(enum) {
    Stderr,
    Stdout,
    Logfile,
};

/// Configuration options for the `Logger`.
pub const LoggerConfig = struct {
    output: Output,
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
        };
        return Self{
            .config = config,
        };
    }

    /// logs message by using structured logging.
    pub fn log(self: *Self, msg: []const u8, args: anytype) void {
        _ = args; // autofix
        switch (self.config.output) {
            .Stdout => {
                const stdout = std.io.getStdOut();
                _ = stdout.write(msg) catch |err| handleErr(err);
            },
            .Stderr => {
                const stderr = std.io.getStdErr();
                _ = stderr.write(msg) catch |err| handleErr(err);
            },
            .Logfile => {
                @panic("ERROR: Not Implemented!");
            },
        }
    }

    fn handleErr(e: anyerror) noreturn {
        std.debug.panic("PANIC: {s}\n", .{@errorName(e)});
    }
    fn handleErrMsg(e: anyerror, msg: []const u8) noreturn {
        std.debug.panic("PANIC: {s}\n because of {s}\n", .{ @errorName(e), msg });
    }
};

pub fn main() !void {
    var logger = Logger.default();
    logger.log("Hello, World\n", .{});
}
