const std = @import("std");
const builtin = @import("builtin");
const app_name = "abmoog";

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};
var chosen_flags: ?[]const []const u8 = null;
var linker_and_include_flags: std.ArrayList([]const u8) = undefined;

const c_sources = [_][]const u8{
    "src/main.c",
};

fn link(allocator: std.mem.Allocator, targets: std.ArrayList(*std.Build.CompileStep), lib: []const u8) !void {
    for (targets.items) |target| {
        target.linkSystemLibrary(lib);
    }
    const str = try std.fmt.allocPrint(allocator, "-l{s}", .{lib});
    try linker_and_include_flags.append(str);
}

fn include(allocator: std.mem.Allocator, targets: std.ArrayList(*std.Build.CompileStep), path: []const u8) !void {
    for (targets.items) |target| {
        target.addIncludePath(path);
    }
    const str = try std.fmt.allocPrint(allocator, "-I{s}", .{path});
    try linker_and_include_flags.append(str);
}

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const mode = b.standardOptimizeOption(.{});

    // this is used in the makeCdb function
    linker_and_include_flags = std.ArrayList([]const u8).init(b.allocator);

    var targets = std.ArrayList(*std.Build.CompileStep).init(b.allocator);

    // create executable
    var exe: *std.Build.CompileStep =
        b.addExecutable(.{
        .name = app_name,
        .optimize = mode,
        .target = target,
    });
    try targets.append(exe);

    switch (mode) {
        .Debug => {
            chosen_flags = &debug_flags;
        },
        else => {
            chosen_flags = &release_flags;
        },
    }

    exe.addCSourceFiles(&c_sources, chosen_flags.?);

    // always link libc
    for (targets.items) |t| {
        t.linkLibC();
    }

    // links and includes which are shared across platforms
    try link(b.allocator, targets, "raylib");
    try link(b.allocator, targets, "chipmunk");
    try include(b.allocator, targets, "src/");

    switch (target.getOsTag()) {
        .wasi, .emscripten => {},
        else => {
            switch (target.getOsTag()) {
                .windows => {
                    try link(b.allocator, targets, "winmm");
                    try link(b.allocator, targets, "gdi32");
                    try link(b.allocator, targets, "opengl32");
                },
                //dunno why but macos target needs sometimes 2 tries to build
                .macos => {
                    try link(b.allocator, targets, "Foundation");
                    try link(b.allocator, targets, "Cocoa");
                    try link(b.allocator, targets, "OpenGL");
                    try link(b.allocator, targets, "CoreAudio");
                    try link(b.allocator, targets, "CoreVideo");
                    try link(b.allocator, targets, "IOKit");
                },
                .linux => {
                    try link(b.allocator, targets, "GL");
                    try link(b.allocator, targets, "rt");
                    try link(b.allocator, targets, "dl");
                    try link(b.allocator, targets, "m");
                    try link(b.allocator, targets, "X11");
                },
                else => {},
            }
        },
    }

    for (targets.items) |t| {
        b.installArtifact(t);
    }

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

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
