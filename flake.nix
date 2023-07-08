{
  description = "Abmoog game for GTMK game jam 2023";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    flake-utils,
    ...
  }: let
    supportedSystems = let
      inherit (flake-utils.lib) system;
    in [
      system.aarch64-linux
      system.x86_64-linux
    ];
  in
    flake-utils.lib.eachSystem supportedSystems (system: let
      pkgs = import nixpkgs {
        inherit system;
        overlays = [
          # zig needs to be overlayed first for other packages which use it
          (_: _: {
            zig = pkgs.callPackage ./nix/zig {
              llvmPackages = pkgs.llvmPackages_16;
            };
          })
          (_: super: {
            raylib = super.callPackage ./nix/raylib {};
            # build chipmunk without demos
            chipmunk = super.callPackage ./nix/chipmunk {originalChipmunk = super.chipmunk;};
            web-raylib = (super.raylib.override {sharedLib = false;}).overrideAttrs (oa: {
              nativeBuildInputs = oa.nativeBuildInputs ++ [super.emscripten];
              cmakeFlags = oa.cmakeFlags ++ ["-DCMAKE_C_COMPILER=emcc"];
              preFixup = "";
              src = (super.callPackage ./nix/raylib {}).src;
              version = (super.callPackage ./nix/raylib {}).version;
              patches = [];
            });
            web-chipmunk = super.chipmunk.overrideAttrs (oa: {
              nativeBuildInputs = oa.nativeBuildInputs ++ [super.emscripten];
              cmakeFlags = (oa.cmakeFlags or []) ++ ["-DCMAKE_C_COMPILER=emcc" "-DBUILD_DEMOS=OFF" "-DBUILD_SHARED=OFF"];
              postInstall = "";
            });
          })
        ];
      };
    in {
      packages = {
        chipmunk = pkgs.chipmunk;
        zig = pkgs.zig;
        raylib = pkgs.raylib;
        web-raylib = pkgs.web-raylib;
        web-chipmunk = pkgs.web-chipmunk;
      };

      devShell =
        pkgs.mkShell.override
        {
          # we only need a compiler because its needed for LSP to find headers
          # otherwise this would be stdenvNoCC
          stdenv = pkgs.clangStdenv;
        }
        {
          packages =
            (with pkgs; [
              clang-tools
              gdb
              valgrind
              chipmunk
              raylib
              pkg-config
              libGL
              self.packages.${system}.zig
            ])
            ++ (with pkgs.xorg; [
              libX11
              libXrandr
              libXinerama
              libXcursor
              libXi
            ]);
        };

      formatter = pkgs.alejandra;
    });
}
