const std = @import("std");

pub fn link(
    allocator: std.mem.Allocator,
    targets: std.ArrayList(*std.Build.CompileStep),
    lib: []const u8,
    flags: *std.ArrayList([]const u8),
) !void {
    for (targets.items) |target| {
        target.linkSystemLibrary(lib);
    }
    const str = try std.fmt.allocPrint(allocator, "-l{s}", .{lib});
    try flags.append(str);
}

pub fn include(
    allocator: std.mem.Allocator,
    targets: std.ArrayList(*std.Build.CompileStep),
    path: []const u8,
    flags: *std.ArrayList([]const u8),
) !void {
    for (targets.items) |target| {
        target.addIncludePath(path);
    }
    const str = try std.fmt.allocPrint(allocator, "-I{s}", .{path});
    try flags.append(str);
}
