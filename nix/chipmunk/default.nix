{originalChipmunk, ...}:
originalChipmunk.overrideAttrs (
  oa: {
    configurePhase = ''
      cmake -S . -B . -DCMAKE_BUILD_TYPE=Debug -DBUILD_DEMOS=OFF -DCMAKE_INSTALL_PREFIX=$out
    '';
    postInstall = "";
    patches = oa.patches ++ [./patches/pkg-config.patch];
  }
)
