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
        overlays = import ./nix/overlays.nix;
      };
    in {
      packages = {
        chipmunk = pkgs.chipmunk;
        zig = pkgs.zig;
        raylib = pkgs.raylib;
        web-raylib = pkgs.web-raylib;
        web-chipmunk = pkgs.web-chipmunk;
        web-build = pkgs.callPackage ./nix/web-build {};
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
              python311
              clang-tools
              gdb
              valgrind
              chipmunk
              raylib
              pkg-config
              libGL
              self.packages.${system}.zig

              # this is just here so that i get intellisense for emscripten stuff
              (linkFarm "emsdk" [
                {
                  path = "${emscripten}/share/emscripten/cache/sysroot/include";
                  name = "include";
                }
              ])
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
