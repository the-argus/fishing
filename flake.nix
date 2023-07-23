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
        overlays = import ./build/nix/overlays.nix;
      };
    in {
      packages = {
        chipmunk = pkgs.chipmunk;
        zig = pkgs.zig;
        raylib = pkgs.raylib;
        web-raylib = pkgs.web-raylib;
        web-chipmunk = pkgs.web-chipmunk;
        web-build = pkgs.callPackage ./build/nix/web-build {};
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
              pkg-config
              libGL
              libGLU
              self.packages.${system}.zig
            ])
            ++ (with pkgs.xorg; [
              libX11
              libXrandr
              libXinerama
              libXcursor
              libXi
            ]);

          shellHook = ''
            export EMSDK="${pkgs.emsdk}"
            export CHIPMUNK="${pkgs.chipmunk}"
            export RAYLIB="${pkgs.raylib}"
          '';
        };

      formatter = pkgs.alejandra;
    });
}
