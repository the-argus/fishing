{
  lib,
  stdenv,
  useWebTarget ? false,
  webTarget ? "wasm32-emscripten",
  zig,
  callPackage,
  coreutils-full,
  mesa,
  glfw,
  libXi,
  libXcursor,
  libXrandr,
  libXinerama,
  libpulseaudio,
  libGLU,
  libX11,
}:
stdenv.mkDerivation rec {
  pname = "raylib";

  inherit (callPackage ./common.nix {}) src version;

  nativeBuildInputs = [zig];

  buildInputs = [
    mesa
    glfw
    libXi
    libXcursor
    libXrandr
    libXinerama
    libpulseaudio
  ];

  propagatedBuildInputs = [libGLU libX11];

  buildPhase = ''
    ${coreutils-full}/bin/chmod +wr . -R
    zig build -Doptimize=ReleaseFast ${lib.optionalString useWebTarget "-Dtarget=${webTarget}"} --global-cache-dir .
  '';

  installPhase = ''
    ls -al
    mkdir -p $out
    cp -r zig-out/* $out
  '';
}
