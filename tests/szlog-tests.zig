// TODO: add unit tests.
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

const std = @import("std");
const Szlog = @import("szlog").Szlog;
const expect = std.testing.expect;

test "bootstrap" {
    var l = Szlog.default();
    l.log("Hello, World", null, .{ "foo", "bar" });
    try expect(true);
}
