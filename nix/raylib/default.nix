{
  stdenv,
  zig,
  fetchFromGitHub,
  coreutils-full,
}:
stdenv.mkDerivation rec {
  pname = "raylib";
  version = "4.5.0";
  src = fetchFromGitHub {
    repo = pname;
    rev = version;
    owner = "raysan5";
    hash = "sha256-Uqqzq5shDp0AgSBT5waHBNUkEu0LRj70SNOlR5R2yAM=";
  };

  nativeBuildInputs = [zig];

  buildPhase = ''
    ${coreutils-full}/bin/chmod +wr . -R
    cd src/
    zig build -Doptimize=ReleaseFast --global-cache-dir ..
  '';

  installPhase = ''
    mkdir -p $out
    cp -r zig-out/* $out
  '';
}
