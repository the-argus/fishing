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

    const chipmunkPrefix = b.option(
        []const u8,
        "chipmunk-prefix",
        "Location where chipmunk include and lib directories can be found",
    ) orelse "";
    const raylibPrefix = b.option(
        []const u8,
        "raylib-prefix",
        "Location where raylib include and lib directories can be found",
    ) orelse "";

    const chipmunk = try optionalPrefixToLibrary(chipmunkPrefix);
    const raylib = try optionalPrefixToLibrary(raylibPrefix);

    switch (target.getOsTag()) {
        .wasi, .emscripten => {
            std.log.info("building for emscripten", .{});
            std.log.warn("The cdb compile step will not work when using the emscripten target.", .{});

            const emscriptenSrc = "build/emscripten/";
            const webOutdir = try std.fs.path.join(b.allocator, &.{ b.install_prefix, "web" });
            const webOutFile = try std.fs.path.join(b.allocator, &.{ webOutdir, "game.html" });

            if (b.sysroot == null) {
                std.log.err("\n\nUSAGE: Please build with 'zig build -Doptimize=ReleaseSmall -Dtarget=wasm32-wasi --sysroot \"$EMSDK/upstream/emscripten\"'\n\n", .{});
                return error.SysRootExpected;
            }

            const lib = b.addStaticLibrary(.{
                .name = app_name,
                .optimize = mode,
                .target = target,
            });

            const emscripten_include_flag = try includePrefixFlag(b.allocator, b.sysroot.?);

            lib.addCSourceFiles(&c_sources, &[_][]const u8{
                try raylib.includeFlag(b.allocator),
                try chipmunk.includeFlag(b.allocator),
                emscripten_include_flag,
            });

            lib.linkLibC();
            lib.defineCMacro("__EMSCRIPTEN__", null);
            lib.defineCMacro("PLATFORM_WEB", null);
            lib.addIncludePath(emscriptenSrc);

            const lib_output_include_flag = try includePrefixFlag(b.allocator, b.install_prefix);
            const shell_file = try std.fs.path.join(b.allocator, &.{ emscriptenSrc, "minshell.html" });

            const emcc = b.addSystemCommand(&.{
                "emcc",
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

            b.installArtifact(lib);

            emcc.step.dependOn(&lib.step);

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
            exe.?.addCSourceFiles(&c_sources, chosen_flags.?);

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
        try raylib.contents.buildFunction(b);
    }
    if (chipmunk.source == .GitModule) {
        try chipmunk.contents.buildFunction(b);
    }

    for (targets.items) |t| {
        b.installArtifact(t);
    }

    // compile commands step
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

const CompileCommandEntry = struct {
    arguments: []const []const u8,
    directory: []const u8,
    file: []const u8,
    output: []const u8,
};
const CompileCommands = [c_sources.len]CompileCommandEntry;

fn makeCdb(step: *std.Build.Step, prog_node: *std.Progress.Node) anyerror!void {
    _ = prog_node;
    _ = step;

    // initialize file and struct containing its future contents
    const cwd: std.fs.Dir = std.fs.cwd();
    var file = try cwd.createFile("compile_commands.json", .{});
    defer file.close();
    var cmp_commands: CompileCommands = undefined;

    var buf: [10000]u8 = undefined;
    var fba = std.heap.FixedBufferAllocator.init(&buf);
    var allocator = fba.allocator();
    const cwd_string = try toString(cwd, allocator);

    // fill each compile command entry, once for each file
    std.debug.assert(cmp_commands.len == c_sources.len);
    for (0.., c_sources) |index, filename| {
        const file_str = try std.fs.path.join(allocator, &[_][]const u8{ cwd_string, filename });
        const output_str = try std.fmt.allocPrint(allocator, "{s}.o", .{file_str});

        var arguments = std.ArrayList([]const u8).init(allocator);
        try arguments.append("clang"); // pretend this is clang compiling
        for (chosen_flags.?) |flag| {
            try arguments.append(flag);
        }
        try arguments.appendSlice(linker_and_include_flags.items);

        cmp_commands[index] = CompileCommandEntry{
            .arguments = try arguments.toOwnedSlice(),
            .output = output_str,
            .file = file_str,
            .directory = cwd_string,
        };
    }

    {
        const options = std.json.StringifyOptions{
            .whitespace = .{
                .indent_level = 0,
                .separator = true,
            },
            .emit_null_optional_fields = false,
        };

        try std.json.stringify(cmp_commands, options, file.writer());
    }

    // finally done using linker_and_include_flags
    linker_and_include_flags.deinit();
}

fn toString(dir: std.fs.Dir, allocator: std.mem.Allocator) ![]const u8 {
    var real_dir = try dir.openDir(".", .{});
    defer real_dir.close();
    return std.fs.realpathAlloc(allocator, ".") catch |err| {
        std.debug.print("error encountered in converting directory to string.\n", .{});
        return err;
    };
}
