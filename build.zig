const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const szlog_lib = b.addStaticLibrary(.{
        .name = "szlog",
        .root_source_file = b.path("src/szlog.zig"),
        .target = target,
        .optimize = optimize,
    });

    b.installArtifact(szlog_lib);

    const mod = b.addModule("szlog", .{
        .root_source_file = b.path("src/szlog.zig"),
    });

    const szlog_unit_tests = b.addTest(.{
        .name = "szlog unit tests",
        .root_source_file = b.path("tests/szlog-tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    szlog_unit_tests.root_module.addImport("szlog", mod);

    const run_tests = b.addRunArtifact(szlog_unit_tests);

    const unit_tests_step = b.step("test", "Run unit tests");
    unit_tests_step.dependOn(&run_tests.step);
}
