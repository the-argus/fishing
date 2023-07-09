# Raylib/Chipmunk Game Project Template

A flexible C game project template. This project:

- Can be built on Windows/Mac/Linux hosts for Windows/Mac/Linux/Web targets.
  (MacOS hosts and targets are currently untested)
- Includes drawing, asset loading, 2D physics, and vector/matrix math.
- Uses Zig as the build system, making it easy to use C++ or Zig in place of C.
- Generates `compile_commands.json`
- Includes a Nix environment, making it very easy to set up on Mac or Linux
  (provided you're okay with installing Nix).

This project does not create any abstraction over raylib and chipmunk, it simply
includes them in the build. This means you will have to deal with the fact that
both libraries have their own implementations of vectors and matrices.

## Raylib

Raylib is an extremely simple yet very complete and easy-to use C API for
creating games. It has almost everything I ever need, with the exception of
physics. I believe this is because raylib tries to be as transparent as possible
in terms of state, so doing something like managing a ton of objects in a
simulation is out of its wheelhouse.

To see if raylib is right for you, check out the [cheatsheet](https://www.raylib.com/cheatsheet/cheatsheet.html).

## Chipmunk2D

Chipmunk2D is my 2D physics library of choice. See the [Hello Chipmunk](https://chipmunk-physics.net/release/ChipmunkLatest-Docs/#Intro-HelloChipmunk)
example to get an idea of what the API is like.

## Planned Features

- Make it easy to swap out Chipmunk for ODE or Bullet for 3D games.
- Hot reloading, probably by using the [MIR](https://github.com/vnmakarov/mir)
  JIT compiler. Unfortunately this JIT only works on Mac/Linux. Might consider
  another JIT for windows support.

## Removing Features You Don't Need

If you don't use Nix, then `rm -rf nix flake.nix flake.lock .envrc`.

If your editor does not use editorconfig or clang-format, remove those dotfiles.

If you don't plan on building for web, `rm -rf emscripten` and delete the
contents of the `.wasi, .emscripten => {` case in the `build.zig.

## Usage

How to install and use this template on different platforms with different tools.

On all platforms, building for desktop is the same: `zig build`. Installing zig
and adding it to your PATH is not covered here.

Add the `-Doptimize=Debug` flag for a debug build.

### Windows

This is the platform for which the process is the most complex.

Install raylib and chipmunk into a systemwide install location. In order to
perform a web build from windows, you need to build both chipmunk and raylib
using emscripten. Install the resulting static libraries somewhere, and then
provide the path to the install prefixes with ``-Draylib-prefix=/path/to/raylib`
and `-Dchipmunk-prefix=/path/to/chipmunk`. You will also need to install the
emscripten SDK and pass its location to the build command.

Here is an example build command:

```bash
zig build -Doptimize=ReleaseSmall \
    -Dtarget=wasm32-wasi \
    --sysroot "$EMSDK/upstream/sysroot" \
    -Dchipmunk-prefix="C:\Program Files\Chipmunk 7.0.3" \
    -Draylib-prefix"C:\raylib" \
```

Notice the `wasm32-wasi` platform.

### Linux

### MacOS

Untested, but in theory the linux instructions should work.

## Credits

Credit to `@ryupold` on GitHub for writing a large portion of the code present
in the `build.zig`. Copied from their [raylib.zig cross platform examples](https://github.com/ryupold/examples-raylib.zig).

## Licensing

This is under the same open-source license as raylib: zlib/libpng.
