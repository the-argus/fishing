const std = @import("std");
const builtin = @import("builtin");

pub fn build(b: *std.Build, app_name: []const u8, mode: std.builtin.Mode, target: std.zig.CrossTarget) !void {
    const emscriptenSrc = "raylib/emscripten/";
    const webCachedir = "zig-cache/web/";
    const webOutdir = "zig-out/web/";

    std.log.info("building for emscripten\n", .{});
    if (b.sysroot == null) {
        std.log.err("\n\nUSAGE: Please build with 'zig build -Doptimize=ReleaseSmall -Dtarget=wasm32-wasi --sysroot \"$EMSDK/upstream/emscripten\"'\n\n", .{});
        return error.SysRootExpected;
    }
    const lib = b.addStaticLibrary(.{
        .name = app_name,
        .optimize = mode,
        .target = target,
    });

    const emcc_file = "emcc";
    const emar_file = "emar";
    const emranlib_file = "emranlib";

    lib.defineCMacro("__EMSCRIPTEN__", null);
    lib.defineCMacro("PLATFORM_WEB", null);
    std.log.info("emscripten include path: {s}", .{include_path});
    lib.addIncludePath(emscriptenSrc);
    lib.addIncludePath("src/raygui");

    const libraryOutputFolder = "zig-out/lib/";
    // this installs the lib (libraylib-zig-examples.a) to the `libraryOutputFolder` folder
    b.installArtifact(lib);

    const shell = switch (mode) {
        .Debug => emscriptenSrc ++ "shell.html",
        else => emscriptenSrc ++ "minshell.html",
    };

    const emcc = b.addSystemCommand(&.{
        emcc_path,
        "-o",
        webOutdir ++ "game.html",

        emscriptenSrc ++ "entry.c",
        "src/raygui/raygui_marshal.c",

        libraryOutputFolder ++ "lib" ++ app_name ++ ".a",
        "-I.",
        "-I" ++ raylibSrc,
        "-I" ++ emscriptenSrc,
        "-Isrc/raygui/",
        "-L.",
        "-L" ++ webCachedir,
        "-L" ++ libraryOutputFolder,
        "-lraylib",
        "-l" ++ app_name,
        "--shell-file",
        shell,
        "-DPLATFORM_WEB",
        "-DRAYGUI_IMPLEMENTATION",
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
        "-O1",
        "-Os",
        // "-sLLD_REPORT_UNDEFINED",
        "-sERROR_ON_UNDEFINED_SYMBOLS=0",

        // optimizations
        "-O1",
        "-Os",

        // "-sUSE_PTHREADS=1",
        // "--profiling",
        // "-sTOTAL_STACK=128MB",
        // "-sMALLOC='emmalloc'",
        // "--no-entry",
        "-sEXPORTED_FUNCTIONS=['_malloc','_free','_main', '_emsc_main','_emsc_set_window_size']",
        "-sEXPORTED_RUNTIME_METHODS=ccall,cwrap",
    });

    emcc.step.dependOn(&lib.step);

    b.getInstallStep().dependOn(&emcc.step);
    //-------------------------------------------------------------------------------------

    std.log.info("\n\nOutput files will be in {s}\n---\ncd {s}\npython -m http.server\n---\n\nbuilding...", .{ webOutdir, webOutdir });
}
