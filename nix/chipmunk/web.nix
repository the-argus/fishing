{
  nixpkgsChipmunk,
  emscripten,
  ...
}:
nixpkgsChipmunk.overrideAttrs (oa: {
  pname = "emscripten-${oa.pname}";
  nativeBuildInputs = oa.nativeBuildInputs ++ [emscripten];
  cmakeFlags = (oa.cmakeFlags or []) ++ ["-DCMAKE_C_COMPILER=emcc" "-DBUILD_DEMOS=OFF" "-DBUILD_SHARED=OFF"];
  postInstall = "";
  postFixup = "${emscripten}/bin/emranlib $out/lib/libchipmunk.a";
})
