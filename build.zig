const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "szlog-exe",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/szlog.zig"),
    });

    const artifact = b.addRunArtifact(exe);

    const runner = b.step("r", "run executable");
    runner.dependOn(&artifact.step);

    const unit_tests = b.addTest(.{
        .name = "szlog unit test",
        .root_source_file = b.path("src/unit_tests.zig"),
        .target = target,
        .optimize = optimize,
    });

    const test_artifact = b.addRunArtifact(unit_tests);

    const unit_tests_runner = b.step("t", "run unit tests");
    unit_tests_runner.dependOn(&test_artifact.step);

    const run_all = b.step("all", "run executable and unit tests");
    run_all.dependOn(&test_artifact.step);
    run_all.dependOn(&artifact.step);
}
