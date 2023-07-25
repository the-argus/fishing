const std = @import("std");
const builtin = @import("builtin");
const app_name = "fishing";

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};
var chosen_flags: ?[]const []const u8 = null;

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
    "src/main.cpp",
    "src/level.cpp",
    "src/render_pipeline.cpp",
    "src/Fisherman.cpp",
    "src/PlaneSet.cpp",
    "src/sound.cpp",
    "src/hud.cpp",
};

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // keep track of any targets we create
    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    // create executable
    var exe: ?*std.Build.CompileStep = null;
    // emscripten library
    var lib: ?*std.Build.CompileStep = null;

    const libraries = try common.getLibraries(b);
    var library_compile_steps = std.ArrayList(*std.Build.CompileStep).init(b.allocator);
    for (libraries) |library| {
        if (library.buildFn) |fun| {
            const compilestep = try fun(b, target, mode);
            try library_compile_steps.append(compilestep);
            // get compile_commands.json for the lib
            try targets.append(compilestep);
        }
    }

    switch (target.getOsTag()) {
        .wasi, .emscripten => {
            const emscriptenSrc = "build/emscripten/";
            const webOutdir = try std.fs.path.join(b.allocator, &.{ b.install_prefix, "web" });
            const webOutFile = try std.fs.path.join(b.allocator, &.{ webOutdir, "game.html" });

            if (b.sysroot == null) {
                std.log.err("\n\nUSAGE: Pass the '--sysroot \"$EMSDK/upstream/emscripten\"' flag.\n\n", .{});
                return;
            }

            lib = b.addStaticLibrary(.{
                .name = app_name,
                .optimize = mode,
                .target = target,
            });
            try targets.append(lib.?);

            const emscripten_include_flag = try includePrefixFlag(b.allocator, b.sysroot.?);

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.append(emscripten_include_flag);
            for (libraries) |library| {
                for (library.allFlags()) |flag| {
                    try flags.append(flag);
                }
            }

            lib.?.addCSourceFiles(&c_sources, try flags.toOwnedSlice());
            lib.?.defineCMacro("__EMSCRIPTEN__", null);
            lib.?.defineCMacro("PLATFORM_WEB", null);
            lib.?.addIncludePath(emscriptenSrc);

            const lib_output_include_flag = try includePrefixFlag(b.allocator, b.install_prefix);
            const shell_file = try std.fs.path.join(b.allocator, &.{ emscriptenSrc, "minshell.html" });
            const emcc_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "bin", "emcc" });

            const command = &[_][]const u8{
                emcc_path,
                "-o",
                webOutFile,
                emscriptenSrc ++ "entry.c",
                "-I.",
                "-L.",
                "-I" ++ emscriptenSrc,
                lib_output_include_flag,
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
            };

            var fullcommand = std.ArrayList([]const u8).init(b.allocator);
            try fullcommand.appendSlice(command);
            for (libraries) |library| {
                try fullcommand.appendSlice(&library.allFlags());
            }

            const emcc = b.addSystemCommand(try fullcommand.toOwnedSlice());

            // also statically link the git libraries
            for (library_compile_steps.items) |lib_cstep| {
                emcc.addArtifactArg(lib_cstep);
            }
            emcc.addArtifactArg(lib.?);
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

            var flags = std.ArrayList([]const u8).init(b.allocator);
            try flags.appendSlice(chosen_flags.?);
            for (libraries) |library| {
                try flags.appendSlice(&library.allFlags());
            }

            // this adds intellisense for any headers which are not present in
            // the source of dependencies, but are built and installed
            try flags.append(try includePrefixFlag(b.allocator, b.install_prefix));
            // intellisense needs to be aware that we're using a newer c++ version
            // (zig does c++20 by default it seems, removing this doesn't cause compiler errors)
            try flags.append("-std=c++20");

            exe.?.addCSourceFiles(&c_sources, try flags.toOwnedSlice());

            // always link libc
            for (targets.items) |t| {
                t.linkLibC();
                t.linkLibCpp();
            }

            // links and includes which are shared across platforms
            try include(targets, "src/");

            // platform-specific additions
            switch (target.getOsTag()) {
                .windows => {},
                .macos => {},
                .linux => {
                    try link(targets, "GL");
                    try link(targets, "X11");
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

    // make the targets depend on the lib compile steps
    for (&[_]?*std.Build.CompileStep{ exe, lib }) |mainstep| {
        if (mainstep) |cstep| {
            for (library_compile_steps.items) |lib_cstep| {
                cstep.step.dependOn(&lib_cstep.step);
                cstep.linkLibrary(lib_cstep);
            }
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
