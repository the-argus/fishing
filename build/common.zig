const std = @import("std");

pub const gitDepDir = "./build/deps/";

pub fn link(
    allocator: std.mem.Allocator,
    targets: std.ArrayList(*std.Build.CompileStep),
    lib: []const u8,
    flags: *std.ArrayList([]const u8),
) !void {
    for (targets.items) |target| {
        target.linkSystemLibrary(lib);
    }
    try flags.append(try linkFlag(allocator, lib));
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
    try flags.append(try includeFlag(allocator, path));
}

pub fn includeFlag(ally: std.mem.Allocator, path: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(ally, "-I{s}", .{path});
}

pub fn linkFlag(ally: std.mem.Allocator, lib: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(ally, "-l{s}", .{lib});
}

pub fn includePrefixFlag(ally: std.mem.Allocator, path: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(ally, "-I{s}/include", .{path});
}

pub fn linkPrefixFlag(ally: std.mem.Allocator, lib: []const u8) ![]const u8 {
    return try std.fmt.allocPrint(ally, "-L{s}/lib", .{lib});
}

const chipmunkBuild = @import("./deps/chipmunk.zig").build;
const raylibBuild = @import("./deps/raylib.zig").build;

pub const LibrarySource = enum { System, GitModule };
pub const LibraryParserError = error{BadName};

pub const Library = struct {
    source: LibrarySource,
    contents: union {
        system: []const u8,
        buildFunction: *const fn (*std.Build) (anyerror!void),
    },

    pub fn includeFlag(self: @This(), ally: std.mem.Allocator) ![]const u8 {
        if (self.source == .System) {
            return includePrefixFlag(ally, self.contents.system);
        } else {
            return "";
        }
    }

    pub fn linkFlag(self: @This(), ally: std.mem.Allocator) ![]const u8 {
        if (self.source == .System) {
            return linkPrefixFlag(ally, self.contents.system);
        } else {
            return std.fmt.allocPrint(ally, "-I{s}{s}", .{ gitDepDir, self.contents.system });
        }
    }
};

pub fn optionalPrefixToLibrary(prefix: []const u8) LibraryParserError!Library {
    if (prefix.len == 0) {
        const res: Library = .{ .source = LibrarySource.GitModule, .contents = .{ .buildFunction = block: {
            if (std.mem.eql(u8, prefix, "chipmunk")) {
                break :block chipmunkBuild;
            } else if (std.mem.eql(u8, prefix, "raylib")) {
                break :block raylibBuild;
            } else {
                return LibraryParserError.BadName;
            }
        } } };
        return res;
    } else {
        return .{ .source = LibrarySource.System, .contents = .{
            .system = prefix,
        } };
    }
}