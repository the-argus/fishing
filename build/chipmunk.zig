const std = @import("std");
const raylib = @import("deps/chipmunk.zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    _ = try raylib.addChipmunk(b, target, optimize);
}
