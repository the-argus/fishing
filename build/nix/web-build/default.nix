{
  stdenv,
  web-raylib,
  web-chipmunk,
  buildPackages,
  zig,
}:
stdenv.mkDerivation {
  pname = "webbuild";
  version = "0.0.1";

  src = ../../..;

  nativeBuildInputs = [zig buildPackages.emscripten];

  buildInputs = [web-raylib web-chipmunk];

  dontConfigure = true;
  dontInstall = true;

  buildPhase = ''
    mkdir -p $out
    zig build \
        -Doptimize=ReleaseSmall \
        -Dtarget=wasm32-wasi \
        --sysroot "${buildPackages.emscripten}/share/emscripten/cache/sysroot" \
        --global-cache-dir . \
        -Dchipmunk-prefix=${web-chipmunk} \
        -Draylib-prefix=${web-raylib} \
        --prefix $out \
        --verbose-cc
  '';
}
