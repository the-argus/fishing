///
/// This file is very similar to raylib's src/build.zig. I copied it out into
/// this repo so that I could have control of its versioning. Otherwise, it
/// breaks whenever you slightly move the version of the zig compiler you are
/// using.
///
/// The over-complicated flags and glfw_flags arraylist is an attempt to
/// generate compile_commands.json. A better approach is probably needed, by
/// intercepting the targets produced by a regular build script.
///
/// FIXME: compile_commands.json doesn't work for MacOS
///
const std = @import("std");

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};
const raylib_flags = [_][]const u8{
    "-std=gnu99",
    "-D_GNU_SOURCE",
    "-DGL_SILENCE_DEPRECATION=199309L",
    "-fno-sanitize=undefined", // https://github.com/raysan5/raylib/issues/1891
};

// rgflw.c needs different flags
var glfw_flags: std.ArrayList([]const u8) = undefined;

const common = @import("./../common.zig");
const include = common.include;
const link = common.link;

const srcdir = "./build/deps/raylib/src/";
const c_sources = [_][]const u8{
    srcdir ++ "raudio.c",
    srcdir ++ "rcore.c",
    srcdir ++ "rmodels.c",
    srcdir ++ "rshapes.c",
    srcdir ++ "rtext.c",
    srcdir ++ "rtextures.c",
    srcdir ++ "utils.c",
};

const BuildError = error{ NoSysroot, UnsupportedOS };

pub fn addLib(b: *std.Build, target: std.zig.CrossTarget, optimize: std.builtin.OptimizeMode) !*std.Build.CompileStep {
    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    var flags = std.ArrayList([]const u8).init(b.allocator);
    glfw_flags = std.ArrayList([]const u8).init(b.allocator);

    try flags.appendSlice(&raylib_flags);
    try glfw_flags.appendSlice(&raylib_flags);

    const raylib = b.addStaticLibrary(.{
        .name = "raylib",
        .target = target,
        .optimize = optimize,
    });
    try targets.append(raylib);

    try flags.append(try common.includeFlag(b.allocator, srcdir ++ "external/glfw/include"));

    // keep track of whether we should append rglfw.c to the source files
    var needs_glfw = false;

    switch (target.getOsTag()) {
        .windows => {
            needs_glfw = true;
            try link(targets, "winmm");
            try link(targets, "gdi32");
            try link(targets, "opengl32");
            try include(targets, srcdir ++ "external/glfw/deps/mingw");

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .linux => {
            needs_glfw = true;
            try link(targets, "GL");
            try link(targets, "rt");
            try link(targets, "dl");
            try link(targets, "m");
            try link(targets, "X11");

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .freebsd, .openbsd, .netbsd, .dragonfly => {
            needs_glfw = true;
            try link(targets, "GL");
            try link(targets, "rt");
            try link(targets, "dl");
            try link(targets, "m");
            try link(targets, "X11");
            try link(targets, "Xrandr");
            try link(targets, "Xinerama");
            try link(targets, "Xi");
            try link(targets, "Xxf86vm");
            try link(targets, "Xcursor");

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .macos => {
            // On macos rglfw.c include Objective-C files.
            const raylib_flags_extra_macos = [_][]const u8{
                "-ObjC",
            };
            try glfw_flags.appendSlice(&raylib_flags_extra_macos);
            needs_glfw = true;
            raylib.linkFramework("Foundation");
            raylib.linkFramework("CoreServices");
            raylib.linkFramework("CoreGraphics");
            raylib.linkFramework("AppKit");
            raylib.linkFramework("IOKit");

            raylib.defineCMacro("PLATFORM_DESKTOP", null);
        },
        .emscripten => {
            raylib.defineCMacro("PLATFORM_WEB", null);
            raylib.defineCMacro("GRAPHICS_API_OPENGL_ES2", null);

            if (b.sysroot == null) {
                std.log.err("Pass '--sysroot \"$EMSDK/upstream/emscripten\"'", .{});
                return BuildError.NoSysroot;
            }

            const ems_include = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "include" });
            try include(targets, ems_include);

            const emranlib_file = switch (b.host.target.os.tag) {
                .windows => "emranlib.bat",
                else => "emranlib",
            };
            // TODO: remove bin if on linux, or make my linux packaging for EMSDK have the same file structure as windows
            const emranlib_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "bin", emranlib_file });
            const run_emranlib = b.addSystemCommand(&.{emranlib_path});
            run_emranlib.addArtifactArg(raylib);
            b.getInstallStep().dependOn(&run_emranlib.step);
        },
        else => {
            std.log.err("Unsupported OS", .{});
            return BuildError.UnsupportedOS;
        },
    }

    raylib.addCSourceFiles(&c_sources, flags.items);
    if (needs_glfw) raylib.addCSourceFile(srcdir ++ "rglfw.c", glfw_flags.items);

    for (targets.items) |t| {
        t.linkLibC();
        b.installArtifact(t);
    }

    raylib.installHeader(srcdir ++ "raylib.h", "raylib.h");
    raylib.installHeader(srcdir ++ "raymath.h", "raymath.h");
    raylib.installHeader(srcdir ++ "rlgl.h", "rlgl.h");

    return raylib;
}
