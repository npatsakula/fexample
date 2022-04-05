# SPDX-FileCopyrightText: 2021 Serokell <https://serokell.io/>
#
# SPDX-License-Identifier: CC0-1.0

{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";
    crate2nix = {
      url = "github:kolloch/crate2nix";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, crate2nix, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        crateName = "fexample";

        inherit (import "${crate2nix}/tools.nix" { inherit pkgs; })
          generatedCargoNix;

        project = import (generatedCargoNix {
          name = crateName;
          src = ./.;
        }) {
          inherit pkgs;
          defaultCrateOverrides = pkgs.defaultCrateOverrides // {
            librocksdb-sys = attrs: {
              nativeBuildInputs = with pkgs; [ jemalloc zstd ];
              buildInputs = with pkgs; [ clang_13 rustfmt ];

              CARGO_CFG_TARGET_FEATURE = "";

              LIBCLANG_PATH = "${pkgs.llvmPackages_13.libclang.lib}/lib";
              CLANG_PATH = "${pkgs.clang_13}/bin/clang";

              extraLinkFlags = [
                "-L${pkgs.llvmPackages_13.libclang}/lib"
                "-L${pkgs.jemalloc}/lib"
                "-L${pkgs.zstd}/lib"
              ];
            };
          };
        };
      in {
        packages.${crateName} = project.rootCrate.build;

        defaultPackage = self.packages.${system}.${crateName};
        defaultApp = self.defaultApp.fexample;

        devShell = pkgs.mkShell {
          inputsFrom = builtins.attrValues self.packages.${system};
          buildInputs = [ pkgs.cargo pkgs.rust-analyzer pkgs.clippy ];
        };
      });
}
