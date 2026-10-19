const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const tc = b.addTranslateC(.{
        .optimize = optimize,
        .target = target,
        .link_libc = true,
        .root_source_file = b.path("c.h"),
    });
    const raylibmod = tc.createModule();
    raylibmod.linkSystemLibrary("raylib", .{});

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("main.zig"),
        .target = target,
        .optimize = optimize,
        .link_libc = true,
    });

    const release = b.addExecutable(.{
        .name = "release",
        .root_module = exe_mod,
        .use_llvm = true,
    });

    const debug = b.addExecutable(.{
        .name = "debug",
        .root_module = b.createModule(.{
            .root_source_file = b.path("main.zig"),
            .target = target,
            .optimize = optimize,
            .link_libc = true,
        }),
        .use_llvm = true,
    });
    b.installArtifact(release);
    b.installArtifact(debug);

    release.root_module.linkSystemLibrary("raylib", .{});
    debug.root_module.linkSystemLibrary("raylib", .{});

    release.root_module.addImport("raylib", raylibmod);
    debug.root_module.addImport("raylib", raylibmod);

    const release_run = b.addRunArtifact(release);
    const debug_run = b.addRunArtifact(release);
    const step = b.step("run", "run it");
    const debug_step = b.step("debug", "debug run it");
    step.dependOn(&release_run.step);
    debug_step.dependOn(&debug_run.step);
    if (b.args) |args| release_run.addArgs(args);
    if (b.args) |args| debug_run.addArgs(args);

    // `zig build check`: type-check everything (including comptime route and
    // SQL generation) without linking a binary. ZLS runs this step on save
    // automatically when a step named "check" exists, so editor diagnostics
    // are the real compiler's, not ZLS's partial analysis.
    const check_exe = b.addExecutable(.{ .name = "check", .root_module = exe_mod });
    const check_tests = b.addTest(.{ .root_module = exe_mod });
    const check_step = b.step("check", "Type-check without emitting a binary");
    check_step.dependOn(&check_exe.step);
    check_step.dependOn(&check_tests.step);
}
