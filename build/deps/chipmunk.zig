const std = @import("std");
const builtin = @import("builtin");
const app_name = "chipmunk";
const srcdir = "./build/deps/chipmunk/";

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};

const common = @import("./../common.zig");
const include = common.include;
const link = common.link;

const c_sources = [_][]const u8{
    srcdir ++ "src/chipmunk.c",
    srcdir ++ "src/cpArbiter.c",
    srcdir ++ "src/cpArray.c",
    srcdir ++ "src/cpBBTree.c",
    srcdir ++ "src/cpBody.c",
    srcdir ++ "src/cpCollision.c",
    srcdir ++ "src/cpConstraint.c",
    srcdir ++ "src/cpDampedRotarySpring.c",
    srcdir ++ "src/cpDampedSpring.c",
    srcdir ++ "src/cpGearJoint.c",
    srcdir ++ "src/cpGrooveJoint.c",
    srcdir ++ "src/cpHashSet.c",
    srcdir ++ "src/cpHastySpace.c",
    srcdir ++ "src/cpMarch.c",
    srcdir ++ "src/cpPinJoint.c",
    srcdir ++ "src/cpPivotJoint.c",
    srcdir ++ "src/cpPolyline.c",
    srcdir ++ "src/cpPolyShape.c",
    srcdir ++ "src/cpRatchetJoint.c",
    srcdir ++ "src/cpRobust.c",
    srcdir ++ "src/cpRotaryLimitJoint.c",
    srcdir ++ "src/cpShape.c",
    srcdir ++ "src/cpSimpleMotor.c",
    srcdir ++ "src/cpSlideJoint.c",
    srcdir ++ "src/cpSpace.c",
    srcdir ++ "src/cpSpaceComponent.c",
    srcdir ++ "src/cpSpaceDebug.c",
    srcdir ++ "src/cpSpaceHash.c",
    srcdir ++ "src/cpSpaceQuery.c",
    srcdir ++ "src/cpSpaceStep.c",
    srcdir ++ "src/cpSpatialIndex.c",
    srcdir ++ "src/cpSweep1D.c",
};

pub fn addLib(b: *std.Build, target: std.zig.CrossTarget, mode: std.builtin.OptimizeMode) !*std.Build.CompileStep {
    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    const lib = b.addStaticLibrary(.{
        .name = app_name,
        .optimize = mode,
        .target = target,
    });
    try targets.append(lib);

    // copied from chipmunk cmake. may be redundant with zig default flags
    // also the compiler is obviously never msvc so idk if the if is necessary
    var flags = std.ArrayList([]const u8).init(b.allocator);
    if (lib.target.getAbi() != .msvc) {
        try flags.appendSlice(&.{ "-fblocks", "-std=gnu99" });
        if (builtin.mode != .Debug) {
            try flags.append("-ffast-math");
        } else {
            try flags.append("-Wall");
        }
    }

    // universal includes / links
    try include(targets, srcdir ++ "include");
    try link(targets, "m");

    switch (target.getOsTag()) {
        .wasi, .emscripten => {
            std.log.info("building for emscripten\n", .{});

            if (b.sysroot == null) {
                std.log.err("\n\nUSAGE: Please build with a specified sysroot: 'zig build --sysroot \"$EMSDK/upstream/emscripten\"'\n\n", .{});
                return error.SysRootExpected;
            }

            // include emscripten headers for compat, for example sys/sysctl
            const emscripten_include_flag = try std.fmt.allocPrint(b.allocator, "-I{s}/include", .{b.sysroot.?});
            try flags.appendSlice(&.{emscripten_include_flag});

            // define some macros in case there web-conditional code in chipmunk
            lib.defineCMacro("__EMSCRIPTEN__", null);
            lib.defineCMacro("PLATFORM_WEB", null);

            // run emranlib
            const emranlib_file = switch (b.host.target.os.tag) {
                .windows => "emranlib.bat",
                else => "emranlib",
            };
            const emranlib_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "bin", emranlib_file });
            const libPath = lib.getOutputSource().getPath(b);
            const emranlib = b.addSystemCommand(&.{
                emranlib_path,
                libPath,
            });
            lib.step.dependOn(&emranlib.step);
        },
        else => {
            switch (mode) {
                .Debug => {
                    try flags.appendSlice(&debug_flags);
                },
                else => {
                    try flags.appendSlice(&release_flags);
                },
            }
            lib.linkLibC();
        },
    }

    lib.addCSourceFiles(&c_sources, flags.items);

    // always install chipmunk headers
    b.installDirectory(.{
        .source_dir = srcdir ++ "include",
        .install_dir = .header,
        .install_subdir = "",
    });

    for (targets.items) |t| {
        b.installArtifact(t);
    }

    return lib;
}
