const std = @import("std");

// Helper function to handle errors with no message.
pub fn handleErr(e: anyerror) noreturn {
    std.debug.panic("PANIC: {s}\n", .{@errorName(e)});
}

// Helper function to handle errors with a message.
pub fn handleErrMsg(e: anyerror, msg: []const u8) noreturn {
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
