const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "szlog-exe",
        .target = target,
        .optimize = optimize,
        .root_source_file = b.path("src/root.zig"),
    });

    const artifact = b.addRunArtifact(exe);

    const runner = b.step("r", "run executable");
    runner.dependOn(&artifact.step);
}
