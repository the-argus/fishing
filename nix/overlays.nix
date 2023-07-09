[
  # zig needs to be overlayed first for other packages which use it
  (_: super: {
    zig = super.callPackage ./zig {
      llvmPackages = super.llvmPackages_16;
    };
  })
  # next do web builds, which are overrides of the nixpkgs ones
  (_: super: {
    web-raylib = super.callPackage ./raylib/web.nix {nixpkgsRaylib = super.raylib;};
    web-chipmunk = super.callPackage ./chipmunk/web.nix {nixpkgsChipmunk = super.chipmunk;};
  })
  # replace nixpkgs ones with my packages
  (_: super: {
    raylib = super.callPackage ./raylib {};
    # build chipmunk without demos
    chipmunk = super.callPackage ./chipmunk {originalChipmunk = super.chipmunk;};
  })
]
