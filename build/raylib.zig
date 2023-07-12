const std = @import("std");
const raylib = @import("deps/raylib.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = try raylib.addRaylib(b, target, optimize);
}
