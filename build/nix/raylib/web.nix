{
  nixpkgsRaylib,
  emscripten,
  callPackage,
  ...
}:
(nixpkgsRaylib.override {sharedLib = false;}).overrideAttrs (oa: {
  pname = "emscripten-${oa.pname}";
  nativeBuildInputs = oa.nativeBuildInputs ++ [emscripten];
  cmakeFlags = oa.cmakeFlags ++ ["-DCMAKE_C_COMPILER=emcc" "-DPLATFORM=Web"];
  preFixup = "";
  inherit (callPackage ./common.nix {}) src version;
  patches = [];
  postFixup = "${emscripten}/bin/emranlib $out/lib/libraylib.a";
})
