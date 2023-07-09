# Raylib/Chipmunk Game Project Template

A flexible C game project template. This project:

- Can be built on Windows/Mac/Linux hosts for Windows/Mac/Linux/Web targets.
- Includes drawing, asset loading, 2D physics, and vector/matrix math.
- Uses Zig as the build system, making it easy to use C++ or Zig in place of C.
- Includes a Nix environment, making it very easy to set up on Mac or Linux
  (provided you're okay with installing Nix).

This project does not create any abstraction over raylib and chipmunk, it simply
includes them in the build. This means you will have to deal with the fact that
both libraries have their own implementations of vectors and matrices.

## Licensing

This is under the same open-source license as raylib: zlib/libpng.
