const std = @import("std");
const builtin = @import("builtin");
const app_name = "ode";
const version = "0.16.0";
const here = "./build/deps/";
const srcdir = here ++ "ode/";

const universal_flags = [_][]const u8{
    "-DODE_LIB", // always build statically
    "-DCCD_IDESINGLE", // single precision floating point
    "-DdIDESINGLE",
    "-DdBUILTIN_THREADING_IMPL_ENABLED",
    "-D_OU_NAMESPACE=odeou",
};

const release_flags = [_][]const u8{"-DNDEBUG"};
const debug_flags = [_][]const u8{};

const windows_flags = [_][]const u8{
    "-D_CRT_SECURE_NO_DEPRECATE",
    "-D_SCL_SECURE_NO_WARNINGS",
    "-D_USE_MATH_DEFINES",
};

const common = @import("./../common.zig");
const include = common.include;
const link = common.link;

const include_dirs = [_][]const u8{
    srcdir ++ "include",
    srcdir ++ "ou/include",
    srcdir ++ "ode/src",
    srcdir ++ "ode/src/joints",
    srcdir ++ "OPCODE",
    srcdir ++ "OPCODE/Ice",
    here ++ "dummyinclude",
};

const c_sources = [_][]const u8{
    srcdir ++ "ode/src/array.cpp",
    srcdir ++ "ode/src/box.cpp",
    srcdir ++ "ode/src/capsule.cpp",
    srcdir ++ "ode/src/collision_cylinder_box.cpp",
    srcdir ++ "ode/src/collision_cylinder_plane.cpp",
    srcdir ++ "ode/src/collision_cylinder_sphere.cpp",
    srcdir ++ "ode/src/collision_kernel.cpp",
    srcdir ++ "ode/src/collision_quadtreespace.cpp",
    srcdir ++ "ode/src/collision_sapspace.cpp",
    srcdir ++ "ode/src/collision_space.cpp",
    srcdir ++ "ode/src/collision_transform.cpp",
    srcdir ++ "ode/src/collision_trimesh_disabled.cpp",
    srcdir ++ "ode/src/collision_util.cpp",
    srcdir ++ "ode/src/convex.cpp",
    srcdir ++ "ode/src/cylinder.cpp",
    srcdir ++ "ode/src/default_threading.cpp",
    srcdir ++ "ode/src/error.cpp",
    srcdir ++ "ode/src/export-dif.cpp",
    srcdir ++ "ode/src/fastdot.cpp",
    srcdir ++ "ode/src/fastldltfactor.cpp",
    srcdir ++ "ode/src/fastldltsolve.cpp",
    srcdir ++ "ode/src/fastlsolve.cpp",
    srcdir ++ "ode/src/fastltsolve.cpp",
    srcdir ++ "ode/src/fastvecscale.cpp",
    srcdir ++ "ode/src/heightfield.cpp",
    srcdir ++ "ode/src/lcp.cpp",
    srcdir ++ "ode/src/mass.cpp",
    srcdir ++ "ode/src/mat.cpp",
    srcdir ++ "ode/src/matrix.cpp",
    srcdir ++ "ode/src/memory.cpp",
    srcdir ++ "ode/src/misc.cpp",
    srcdir ++ "ode/src/nextafterf.c",
    srcdir ++ "ode/src/objects.cpp",
    srcdir ++ "ode/src/obstack.cpp",
    srcdir ++ "ode/src/ode.cpp",
    srcdir ++ "ode/src/odeinit.cpp",
    srcdir ++ "ode/src/odemath.cpp",
    srcdir ++ "ode/src/plane.cpp",
    srcdir ++ "ode/src/quickstep.cpp",
    srcdir ++ "ode/src/ray.cpp",
    srcdir ++ "ode/src/resource_control.cpp",
    srcdir ++ "ode/src/rotation.cpp",
    srcdir ++ "ode/src/simple_cooperative.cpp",
    srcdir ++ "ode/src/sphere.cpp",
    srcdir ++ "ode/src/step.cpp",
    srcdir ++ "ode/src/threading_base.cpp",
    srcdir ++ "ode/src/threading_impl.cpp",
    srcdir ++ "ode/src/threading_pool_posix.cpp",
    srcdir ++ "ode/src/threading_pool_win.cpp",
    srcdir ++ "ode/src/timer.cpp",
    srcdir ++ "ode/src/util.cpp",
    srcdir ++ "ode/src/joints/amotor.cpp",
    srcdir ++ "ode/src/joints/ball.cpp",
    srcdir ++ "ode/src/joints/contact.cpp",
    srcdir ++ "ode/src/joints/dball.cpp",
    srcdir ++ "ode/src/joints/dhinge.cpp",
    srcdir ++ "ode/src/joints/fixed.cpp",
    srcdir ++ "ode/src/joints/hinge.cpp",
    srcdir ++ "ode/src/joints/hinge2.cpp",
    srcdir ++ "ode/src/joints/joint.cpp",
    srcdir ++ "ode/src/joints/lmotor.cpp",
    srcdir ++ "ode/src/joints/null.cpp",
    srcdir ++ "ode/src/joints/piston.cpp",
    srcdir ++ "ode/src/joints/plane2d.cpp",
    srcdir ++ "ode/src/joints/pr.cpp",
    srcdir ++ "ode/src/joints/pu.cpp",
    srcdir ++ "ode/src/joints/slider.cpp",
    srcdir ++ "ode/src/joints/transmission.cpp",
    srcdir ++ "ode/src/joints/universal.cpp",

    // now the OPCODE sources
    srcdir ++ "ode/src/collision_convex_trimesh.cpp",
    srcdir ++ "ode/src/collision_cylinder_trimesh.cpp",
    srcdir ++ "ode/src/collision_trimesh_box.cpp",
    srcdir ++ "ode/src/collision_trimesh_ccylinder.cpp",
    srcdir ++ "ode/src/collision_trimesh_internal.cpp",
    srcdir ++ "ode/src/collision_trimesh_opcode.cpp",
    srcdir ++ "ode/src/collision_trimesh_plane.cpp",
    srcdir ++ "ode/src/collision_trimesh_ray.cpp",
    srcdir ++ "ode/src/collision_trimesh_sphere.cpp",
    srcdir ++ "ode/src/collision_trimesh_trimesh.cpp",
    srcdir ++ "ode/src/collision_trimesh_trimesh_old.cpp",
    srcdir ++ "OPCODE/OPC_AABBCollider.cpp",
    srcdir ++ "OPCODE/OPC_AABBTree.cpp",
    srcdir ++ "OPCODE/OPC_BaseModel.cpp",
    srcdir ++ "OPCODE/OPC_Collider.cpp",
    srcdir ++ "OPCODE/OPC_Common.cpp",
    srcdir ++ "OPCODE/OPC_HybridModel.cpp",
    srcdir ++ "OPCODE/OPC_LSSCollider.cpp",
    srcdir ++ "OPCODE/OPC_MeshInterface.cpp",
    srcdir ++ "OPCODE/OPC_Model.cpp",
    srcdir ++ "OPCODE/OPC_OBBCollider.cpp",
    srcdir ++ "OPCODE/OPC_OptimizedTree.cpp",
    srcdir ++ "OPCODE/OPC_Picking.cpp",
    srcdir ++ "OPCODE/OPC_PlanesCollider.cpp",
    srcdir ++ "OPCODE/OPC_RayCollider.cpp",
    srcdir ++ "OPCODE/OPC_SphereCollider.cpp",
    srcdir ++ "OPCODE/OPC_TreeBuilders.cpp",
    srcdir ++ "OPCODE/OPC_TreeCollider.cpp",
    srcdir ++ "OPCODE/OPC_VolumeCollider.cpp",
    srcdir ++ "OPCODE/Opcode.cpp",
    srcdir ++ "OPCODE/Ice/IceAABB.cpp",
    srcdir ++ "OPCODE/Ice/IceContainer.cpp",
    srcdir ++ "OPCODE/Ice/IceHPoint.cpp",
    srcdir ++ "OPCODE/Ice/IceIndexedTriangle.cpp",
    srcdir ++ "OPCODE/Ice/IceMatrix3x3.cpp",
    srcdir ++ "OPCODE/Ice/IceMatrix4x4.cpp",
    srcdir ++ "OPCODE/Ice/IceOBB.cpp",
    srcdir ++ "OPCODE/Ice/IcePlane.cpp",
    srcdir ++ "OPCODE/Ice/IcePoint.cpp",
    srcdir ++ "OPCODE/Ice/IceRandom.cpp",
    srcdir ++ "OPCODE/Ice/IceRay.cpp",
    srcdir ++ "OPCODE/Ice/IceRevisitedRadix.cpp",
    srcdir ++ "OPCODE/Ice/IceSegment.cpp",
    srcdir ++ "OPCODE/Ice/IceTriangle.cpp",
    srcdir ++ "OPCODE/Ice/IceUtils.cpp",

    srcdir ++ "ou/src/ou/atomic.cpp",
    srcdir ++ "ou/src/ou/customization.cpp",
    srcdir ++ "ou/src/ou/malloc.cpp",
    srcdir ++ "ou/src/ou/threadlocalstorage.cpp",
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

    try flags.appendSlice(&universal_flags);

    if (mode != .Debug) {
        try flags.appendSlice(&debug_flags);
    } else {
        try flags.appendSlice(&release_flags);
    }

    {
        const os_number: i32 = switch ((try std.zig.system.NativeTargetInfo.detect(target)).target.os.tag) {
            .linux => 1,
            .windows => 2,
            // .qnx => 3, // not supported by zig
            .macos => 4,
            .aix => 5,
            // .sunos => 6, //also not supported
            .ios => 7,
            else => {
                return error.UnsupportedOs;
            },
        };
        try flags.append(try std.fmt.allocPrint(b.allocator, "-D_OU_TARGET_OS={any}", .{os_number}));
    }

    for (include_dirs) |include_dir| {
        try include(targets, include_dir);
    }

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

            // define some macros in case there web-conditional code in ode
            lib.defineCMacro("__EMSCRIPTEN__", null);

            // run emranlib
            const emranlib_file = switch (b.host.target.os.tag) {
                .windows => "emranlib.bat",
                else => "emranlib",
            };
            // TODO: remove bin if on linux, or make my linux packaging for EMSDK have the same file structure as windows
            const emranlib_path = try std.fs.path.join(b.allocator, &.{ b.sysroot.?, "bin", emranlib_file });
            const run_emranlib = b.addSystemCommand(&.{emranlib_path});
            run_emranlib.addArtifactArg(lib);
            b.getInstallStep().dependOn(&run_emranlib.step);
        },
        else => {
            lib.linkLibC();
            lib.linkLibCpp();
        },
    }

    lib.addCSourceFiles(&c_sources, flags.items);

    // always install ode headers
    b.installDirectory(.{
        .source_dir = std.Build.FileSource{ .path = srcdir ++ "include" },
        .install_dir = .header,
        .install_subdir = "",
    });

    for (targets.items) |t| {
        b.installArtifact(t);
    }

    return lib;
}
