{
  lib,
  stdenv,
  useWebTarget ? false,
  webTarget ? "wasm32-emscripten",
  zig,
  fetchFromGitHub,
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
  version = "4.5.0";
  src = fetchFromGitHub {
    repo = pname;
    rev = "ed2caa12775da95d3e19ce42dccdca4a0ba8f8a0";
    owner = "raysan5";
    hash = "sha256-EcY0Z9AsEm2B9DeA2LXSv6iJX4DwC8Gh+NNJp/F2zkQ=";
  };

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
    zig build -Doptimize=ReleaseFast ${lib.optionalString useWebTarget "-Dtarget=${webTarget}"} --global-cache-dir ..
  '';

  installPhase = ''
    ls -al
    mkdir -p $out
    cp -r zig-out/* $out
  '';
}
