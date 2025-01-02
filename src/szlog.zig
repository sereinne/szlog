//! A simple structured logging library in Zig.

const std = @import("std");
const format = @import("format.zig");
const utils = @import("utils.zig");
const colors = @import("color.zig");

const Formatter = format.Formatter;
const TextFormatter = format.TextFormatter;
const Colorizer = colors.Colorizer;
const File = std.fs.File;

/// All types of possible output where all log messages go.
pub const Output = union(enum) {
    /// Logs into standard out.
    stdout,
    /// Logs into standard err.
    stderr,
    /// Logs into a file.
    logfile: File,
};

/// Configuration options for `Szlog`.
pub const SzlogOptions = struct {
    /// Where the logs are going to go.
    output: Output,
    /// How the logs are formatted.
    formatter: Formatter,
};

/// Structured Logger (can modify the behaviour by tweaking `SzlogOptions`).
pub const Szlog = struct {
    const Self = @This();
    /// Options (see `SzlogOptions`).
    opts: SzlogOptions,

    /// Initialize `Szlog` with default `SzlogOptions`.
    pub fn default() Self {
        const opts = SzlogOptions{
            .output = .stdout,
            .formatter = .{ .text = TextFormatter.default() },
        };
        return Self{
            .opts = opts,
        };
    }

    /// Initialize `Szlog` with user's configuration of `SzlogOptions`.
    pub fn new(opts: SzlogOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    /// Logs message using structured logging.
    /// TODO: handle error more gracefully.
    pub fn log(self: *Self, comptime message: []const u8, comptime color: ?Colorizer, args: anytype) void {
        switch (self.opts.output) {
            .stdout => {
                const stdout_writer = std.io.getStdOut().writer();
                const res = self.opts.formatter.format(message, color, args);
                stdout_writer.print("{s}", .{res}) catch |err| utils.handleErr(err);
            },
            .stderr => {
                const stderr_writer = std.io.getStdErr().writer();
                const res = self.opts.formatter.format(message, color, args);
                stderr_writer.print("{s}", .{res}) catch |err| utils.handleErr(err);
            },
            .logfile => |file| {
                const file_writer = file.writer();
                const res = self.opts.formatter.format(message, color, args);
                file_writer.print("{s}", .{res}) catch |err| utils.handleErr(err);
            },
        }
    }
};
