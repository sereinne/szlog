const std = @import("std");
const expect = std.testing.expect;
const concatenate = @import("szlog.zig").Logger.concatenate;
const isStringType = @import("szlog.zig").Logger.isStringType;

test "check concatenation over user arguments" {
    const args = .{ "foo", "bar", "baz", "bah", "k1", "v1" };

    comptime var tmp: []const u8 = "";
    inline for (args, 0..) |key, idx| {
        // Check for out of bounds index.
        if (idx == args.len - 1) {
            // If the arguments length is odd, that means there is a key that has no value.
            if (args.len % 2 != 0) {
                tmp = tmp ++ std.fmt.comptimePrint("{s}=None ", .{key});
                break;
            }
            break;
        }
        const value = args[idx + 1];
        // The key is always at the even index (starts at 0), meanwhile the value is always at the odd index (starts at 1).
        if (idx % 2 == 0) {
            tmp = tmp ++ std.fmt.comptimePrint("{s}={s} ", .{ key, value });
        }
    }

    try expect(std.mem.eql(u8, tmp, "foo=bar baz=bah k1=v1 "));
}

test "test drive isStringType function" {
    const a = .{"foo"};
    try expect(isStringType(a[0]));

    const b: []const u8 = "foo";
    try expect(isStringType(b));
}
