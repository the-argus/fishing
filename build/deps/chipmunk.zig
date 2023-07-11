const std = @import("std");
const builtin = @import("builtin");
const app_name = "chipmunk";

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};
var linker_and_include_flags: std.ArrayList([]const u8) = undefined;

const include = @import("../common.zig").include;
const link = @import("../common.zig").link;

const c_sources = [_][]const u8{
    "chipmunk/src/chipmunk.c",
    "chipmunk/src/cpArbiter.c",
    "chipmunk/src/cpArray.c",
    "chipmunk/src/cpBBTree.c",
    "chipmunk/src/cpBody.c",
    "chipmunk/src/cpCollision.c",
    "chipmunk/src/cpConstraint.c",
    "chipmunk/src/cpDampedRotarySpring.c",
    "chipmunk/src/cpDampedSpring.c",
    "chipmunk/src/cpGearJoint.c",
    "chipmunk/src/cpGrooveJoint.c",
    "chipmunk/src/cpHashSet.c",
    "chipmunk/src/cpHastySpace.c",
    "chipmunk/src/cpMarch.c",
    "chipmunk/src/cpPinJoint.c",
    "chipmunk/src/cpPivotJoint.c",
    "chipmunk/src/cpPolyline.c",
    "chipmunk/src/cpPolyShape.c",
    "chipmunk/src/cpRatchetJoint.c",
    "chipmunk/src/cpRobust.c",
    "chipmunk/src/cpRotaryLimitJoint.c",
    "chipmunk/src/cpShape.c",
    "chipmunk/src/cpSimpleMotor.c",
    "chipmunk/src/cpSlideJoint.c",
    "chipmunk/src/cpSpace.c",
    "chipmunk/src/cpSpaceComponent.c",
    "chipmunk/src/cpSpaceDebug.c",
    "chipmunk/src/cpSpaceHash.c",
    "chipmunk/src/cpSpaceQuery.c",
    "chipmunk/src/cpSpaceStep.c",
    "chipmunk/src/cpSpatialIndex.c",
    "chipmunk/src/cpSweep1D.c",
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // this is used in the makeCdb function
    linker_and_include_flags = std.ArrayList([]const u8).init(b.allocator);

    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    const lib = b.addStaticLibrary(.{
        .name = app_name,
        .optimize = mode,
        .target = target,
    });
    try targets.append(lib);

    // copied from chipmunk cmake. may be redundant with zig default flags
    // also the compiler is obviously never msvc so idk if the if is necessary
    if (lib.target.getAbi() != .msvc) {
        try linker_and_include_flags.appendSlice(&.{ "-fblocks", "-std=gnu99" });
        if (builtin.mode != .Debug) {
            try linker_and_include_flags.append("-ffast-math");
        } else {
            try linker_and_include_flags.append("-Wall");
        }
    }

    // universal includes / links
    try include(b.allocator, targets, "./chipmunk/include", &linker_and_include_flags);
    try link(b.allocator, targets, "m", &linker_and_include_flags);

    switch (target.getOsTag()) {
        .wasi, .emscripten => {
            std.log.info("building for emscripten\n", .{});

            if (b.sysroot == null) {
                std.log.err("\n\nUSAGE: Please build with a specified sysroot: 'zig build --sysroot \"$EMSDK/upstream/emscripten\"'\n\n", .{});
                return error.SysRootExpected;
            }

            // include emscripten headers for compat, for example sys/sysctl
            const emscripten_include_flag = try std.fmt.allocPrint(b.allocator, "-I{s}/include", .{b.sysroot.?});
            try linker_and_include_flags.appendSlice(&.{emscripten_include_flag});

            // define some macros in case there web-conditional code in chipmunk
            lib.defineCMacro("__EMSCRIPTEN__", null);
            lib.defineCMacro("PLATFORM_WEB", null);

            // run emranlib
            const emranlib_file = switch (b.host.target.os.tag) {
                .windows => "emranlib.bat",
                else => "emranlib",
            };
            const emranlib_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, emranlib_file });
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
                    try linker_and_include_flags.appendSlice(&debug_flags);
                },
                else => {
                    try linker_and_include_flags.appendSlice(&release_flags);
                },
            }
            lib.linkLibC();
        },
    }

    lib.addCSourceFiles(&c_sources, linker_and_include_flags.items);

    // always install chipmunk headers
    b.installDirectory(.{
        .source_dir = "./chipmunk/include",
        .install_dir = .header,
        .install_subdir = "",
    });

    for (targets.items) |t| {
        b.installArtifact(t);
    }
}
