const std = @import("std");

var compile_steps: ?std.ArrayList(*std.Build.CompileStep) = null;

const CSourceFiles = std.Build.CompileStep.CSourceFiles;

const CompileCommandEntry = struct {
    arguments: []const []const u8,
    directory: []const u8,
    file: []const u8,
    output: []const u8,
};

const CompileCommandError = error{
    UnregisteredCompileSteps,
    UnregisteredAllocator,
};

pub fn registerCompileSteps(input_steps: std.ArrayList(*std.Build.CompileStep)) void {
    compile_steps = input_steps;
}

// NOTE: some of the CSourceFiles pointed at by the elements of the returned
// array are allocated with the allocator, some are not.
fn getCSources(allocator: std.mem.Allocator) ![]*CSourceFiles {
    var res = std.ArrayList(*CSourceFiles).init(allocator);

    var index: u32 = 0;

    while (index < compile_steps.?.items.len) {
        const step = compile_steps.?.items[index];
        for (step.link_objects.items) |link_object| {
            switch (link_object) {
                .static_path => {
                    continue;
                },
                .other_step => {
                    try compile_steps.?.append(link_object.other_step);
                },
                .system_lib => {
                    continue;
                },
                .assembly_file => {
                    continue;
                },
                .c_source_file => {
                    // convert C source file into c source fileS
                    const path = link_object.c_source_file.source.path;
                    var files_mem = try allocator.alloc([]const u8, 1);
                    files_mem[0] = path;

                    var source_file = try allocator.create(CSourceFiles);

                    source_file.* = CSourceFiles{
                        .files = files_mem,
                        .flags = link_object.c_source_file.args,
                    };

                    try res.append(source_file);
                },
                .c_source_files => {
                    try res.append(link_object.c_source_files);
                },
            }
        }
        index += 1;
    }

    return res.toOwnedSlice();
}

pub fn makeCdb(step: *std.Build.Step, prog_node: *std.Progress.Node) anyerror!void {
    if (compile_steps == null) {
        std.log.err("No compile steps registered. Call registerCompileSteps before creating the makeCdb step.", .{});
        return CompileCommandError.UnregisteredCompileSteps;
    }
    _ = prog_node;
    var allocator = step.owner.allocator;

    var compile_commands = std.ArrayList(CompileCommandEntry).init(allocator);
    defer compile_commands.deinit();

    // initialize file and struct containing its future contents
    const cwd: std.fs.Dir = std.fs.cwd();
    var file = try cwd.createFile("compile_commands.json", .{});
    defer file.close();

    const cwd_string = try toString(cwd, allocator);
    const c_sources = try getCSources(allocator);

    // fill compile command entries, one for each file
    for (c_sources) |c_source_file_set| {
        const flags = c_source_file_set.flags;
        for (c_source_file_set.files) |c_file| {
            const file_str = try std.fs.path.join(allocator, &[_][]const u8{ cwd_string, c_file });
            const output_str = try std.fmt.allocPrint(allocator, "{s}.o", .{file_str});

            var arguments = std.ArrayList([]const u8).init(allocator);
            try arguments.append("clang"); // pretend this is clang compiling
            try arguments.append(c_file);
            try arguments.appendSlice(&.{ "-o", try std.fmt.allocPrint(allocator, "{s}.o", .{c_file}) });
            try arguments.appendSlice(flags);

            const entry = CompileCommandEntry{
                .arguments = try arguments.toOwnedSlice(),
                .output = output_str,
                .file = file_str,
                .directory = cwd_string,
            };
            try compile_commands.append(entry);
        }
    }

    try writeCompileCommands(&file, compile_commands.items);
}

fn writeCompileCommands(file: *std.fs.File, compile_commands: []CompileCommandEntry) !void {
    const options = std.json.StringifyOptions{
        .whitespace = .{
            .indent_level = 0,
            .separator = true,
        },
        .emit_null_optional_fields = false,
    };

    try std.json.stringify(compile_commands, options, file.*.writer());
}

fn toString(dir: std.fs.Dir, allocator: std.mem.Allocator) ![]const u8 {
    var real_dir = try dir.openDir(".", .{});
    defer real_dir.close();
    return std.fs.realpathAlloc(allocator, ".") catch |err| {
        std.debug.print("error encountered in converting directory to string.\n", .{});
        return err;
    };
}
