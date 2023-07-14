const std = @import("std");
const builtin = @import("builtin");
const app_name = "abmoog";

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};
var chosen_flags: ?[]const []const u8 = null;
var linker_and_include_flags: std.ArrayList([]const u8) = undefined;

const common = @import("./build/common.zig");
const include = common.include;
const link = common.link;
const linkFlag = common.linkFlag;
const includeFlag = common.includeFlag;
const linkPrefixFlag = common.linkPrefixFlag;
const includePrefixFlag = common.includePrefixFlag;
const optionalPrefixToLibrary = common.optionalPrefixToLibrary;

const cdb = @import("./build/compile_commands.zig");
const makeCdb = cdb.makeCdb;

const c_sources = [_][]const u8{
    "src/main.c",
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // this is used in the makeCdb function
    linker_and_include_flags = std.ArrayList([]const u8).init(b.allocator);

    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    // create executable
    var exe: ?*std.Build.CompileStep = null;
    // emscripten library
    var lib: ?*std.Build.CompileStep = null;

    const chipmunkPrefix = b.option(
        []const u8,
        "chipmunk-prefix",
        "Location where chipmunk include and lib directories can be found",
    ) orelse null;
    const raylibPrefix = b.option(
        []const u8,
        "raylib-prefix",
        "Location where raylib include and lib directories can be found",
    ) orelse null;

    const chipmunk = try optionalPrefixToLibrary(chipmunkPrefix, .Chipmunk);
    const raylib = try optionalPrefixToLibrary(raylibPrefix, .Raylib);

    switch (target.getOsTag()) {
        .wasi, .emscripten => {
            std.log.info("building for emscripten", .{});
            std.log.warn("The cdb compile step will not work when using the emscripten target.", .{});

            const emscriptenSrc = "build/emscripten/";
            const webOutdir = try std.fs.path.join(b.allocator, &.{ b.install_prefix, "web" });
            const webOutFile = try std.fs.path.join(b.allocator, &.{ webOutdir, "game.html" });

            if (b.sysroot == null) {
                std.log.err("\n\nUSAGE: Pass the '--sysroot \"$EMSDK/upstream/emscripten\"' flag.\n\n", .{});
                return error.SysRootExpected;
            }

            lib = b.addStaticLibrary(.{
                .name = app_name,
                .optimize = mode,
                .target = target,
            });
            try targets.append(lib.?);

            const emscripten_include_flag = try includePrefixFlag(b.allocator, b.sysroot.?);

            try include(b.allocator, targets, "./zig-out/include", &linker_and_include_flags);
            try linker_and_include_flags.append(try linkPrefixFlag(b.allocator, "./zig-out"));
            lib.?.addCSourceFiles(&c_sources, block: {
                const flags = &[_][]const u8{
                    try raylib.includeFlag(b.allocator),
                    try chipmunk.includeFlag(b.allocator),
                    emscripten_include_flag,
                };
                try linker_and_include_flags.appendSlice(flags);
                break :block linker_and_include_flags.items;
            });

            lib.?.defineCMacro("__EMSCRIPTEN__", null);
            lib.?.defineCMacro("PLATFORM_WEB", null);
            lib.?.addIncludePath(emscriptenSrc);

            const lib_output_include_flag = try includePrefixFlag(b.allocator, b.install_prefix);
            const shell_file = try std.fs.path.join(b.allocator, &.{ emscriptenSrc, "minshell.html" });
            const emcc_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "bin", "emcc" });

            const emcc = b.addSystemCommand(&.{
                emcc_path,
                "-o",
                webOutFile,
                emscriptenSrc ++ "entry.c",
                "-I.",
                "-L.",
                "-I" ++ emscriptenSrc,
                lib_output_include_flag,
                try chipmunk.linkFlag(b.allocator),
                try chipmunk.includeFlag(b.allocator),
                try raylib.includeFlag(b.allocator),
                try raylib.linkFlag(b.allocator),
                "-lraylib",
                "-lchipmunk",
                "-l" ++ app_name,
                "--shell-file",
                shell_file,
                "-DPLATFORM_WEB",
                "-sUSE_GLFW=3",
                "-sWASM=1",
                "-sALLOW_MEMORY_GROWTH=1",
                "-sWASM_MEM_MAX=512MB", //going higher than that seems not to work on iOS browsers ¯\_(ツ)_/¯
                "-sTOTAL_MEMORY=512MB",
                "-sABORTING_MALLOC=0",
                "-sASYNCIFY",
                "-sFORCE_FILESYSTEM=1",
                "-sASSERTIONS=1",
                "--memory-init-file",
                "0",
                "--preload-file",
                "assets",
                "--source-map-base",
                // "-sLLD_REPORT_UNDEFINED",
                "-sERROR_ON_UNDEFINED_SYMBOLS=0",
                // optimizations
                "-O3",
                // "-Os",
                // "-sUSE_PTHREADS=1",
                // "--profiling",
                // "-sTOTAL_STACK=128MB",
                // "-sMALLOC='emmalloc'",
                // "--no-entry",
                "-sEXPORTED_FUNCTIONS=['_malloc','_free','_main', '_emsc_main','_emsc_set_window_size']",
                "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap",
            });

            emcc.step.dependOn(&lib.?.step);

            b.getInstallStep().dependOn(&emcc.step);

            std.fs.cwd().makePath(webOutdir) catch {};

            std.log.info(
                \\
                \\Output files will be in {s}
                \\
                \\---
                \\cd {s}
                \\python -m http.server
                \\---
                \\
                \\building...
            ,
                .{ webOutdir, webOutdir },
            );
        },
        else => {
            exe = b.addExecutable(.{
                .name = app_name,
                .optimize = mode,
                .target = target,
            });
            try targets.append(exe.?);

            chosen_flags = if (mode == .Debug) &debug_flags else &release_flags;
            try linker_and_include_flags.appendSlice(chosen_flags.?);
            try include(b.allocator, targets, "./zig-out/include", &linker_and_include_flags);
            try linker_and_include_flags.append(try linkPrefixFlag(b.allocator, "./zig-out"));

            exe.?.addCSourceFiles(&c_sources, linker_and_include_flags.items);

            // always link libc
            for (targets.items) |t| {
                t.linkLibC();
            }

            // links and includes which are shared across platforms
            try link(b.allocator, targets, "raylib", &linker_and_include_flags);
            try link(b.allocator, targets, "chipmunk", &linker_and_include_flags);
            try include(b.allocator, targets, "src/", &linker_and_include_flags);

            // platform-specific additions
            switch (target.getOsTag()) {
                .windows => {},
                .macos => {},
                .linux => {
                    try link(b.allocator, targets, "GL", &linker_and_include_flags);
                    try link(b.allocator, targets, "X11", &linker_and_include_flags);
                },
                else => {},
            }

            const run_cmd = b.addRunArtifact(exe.?);
            run_cmd.step.dependOn(b.getInstallStep());
            if (b.args) |args| {
                run_cmd.addArgs(args);
            }

            const run_step = b.step("run", "Run the app");
            run_step.dependOn(&run_cmd.step);
        },
    }

    // call the library build functions if they're git modules
    if (raylib.source == .GitModule) {
        const raylib_step = try raylib.contents.buildFunction(b, target, mode);
        if (exe) |game| {
            game.step.dependOn(&raylib_step.step);
        }
        if (lib) |emscripten_lib| {
            emscripten_lib.step.dependOn(&raylib_step.step);
        }
    }
    if (chipmunk.source == .GitModule) {
        const chipmunk_step = try chipmunk.contents.buildFunction(b, target, mode);
        if (exe) |game| {
            game.step.dependOn(&chipmunk_step.step);
        }
        if (lib) |emscripten_lib| {
            emscripten_lib.step.dependOn(&chipmunk_step.step);
        }
    }

    for (targets.items) |t| {
        b.installArtifact(t);
    }

    // compile commands step
    cdb.registerCompileSteps(targets);

    var step = try b.allocator.create(std.Build.Step);
    step.* = std.Build.Step.init(.{
        .id = .custom,
        .name = "cdb_file",
        .makeFn = makeCdb,
        .owner = b,
    });

    const cdb_step = b.step("cdb", "Create compile_commands.json");
    cdb_step.dependOn(step);
}
