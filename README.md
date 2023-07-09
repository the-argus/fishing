# Raylib/Chipmunk Game Project Template

A flexible C game project template. This project:

- Can be built on Windows/Mac/Linux hosts for Windows/Mac/Linux/Web targets.
  (MacOS hosts and target are currently untested)
- Includes drawing, asset loading, 2D physics, and vector/matrix math.
- Uses Zig as the build system, making it easy to use C++ or Zig in place of C.
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

## Credits

Credit to `@ryupold` on GitHub for writing a large portion of the code present
in the `build.zig`. Copied from their [raylib.zig cross platform examples](https://github.com/ryupold/examples-raylib.zig)

## Licensing

This is under the same open-source license as raylib: zlib/libpng.
