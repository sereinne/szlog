const std = @import("std");
const format = @import("format.zig");
const utils = @import("utils.zig");
const colors = @import("color.zig");

const Formatter = format.Formatter;
const TextFormatter = format.TextFormatter;
const Colorizer = colors.Colorizer;
const File = std.fs.File;

// USAGE:
// -- destination of log messages
// type output = either stdout stderr logfile;
// -- formatter can format and also color the messages.
// type formatter = text json;
// type logger = {
//    output: output,
//    formatter: formatter,
// }
//
// pub fn main() void {
//      const config = LoggerConfig = .{
//          .output = output
//          .formatter = formatter
//      };
//      var logger = Logger.default(); // or Logger.new(config);
// }

pub const Output = union(enum) { stdout, stderr, logfile: File };

pub const LoggerOptions = struct {
    output: Output,
    formatter: Formatter,
};

pub const Logger = struct {
    const Self = @This();
    opts: LoggerOptions,

    pub fn default() Self {
        const opts = LoggerOptions{
            .output = .stdout,
            .formatter = .{ .text = TextFormatter.default() },
        };
        return Self{
            .opts = opts,
        };
    }

    pub fn new(opts: LoggerOptions) Self {
        return Self{
            .opts = opts,
        };
    }

    // no going to handle errors right now (it will just panic).
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

pub fn main() void {
    const color = Colorizer{ .eightbit = .{ .mode = 1, .bg = 51, .fg = 31 } };
    var l = Logger.new(.{ .output = .stdout, .formatter = .{ .text = format.TextFormatter.default() } });
    l.log("Hello, World", color, .{ "foo", "args" });
}
