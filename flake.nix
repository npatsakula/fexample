{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
    utils.url = "github:numtide/flake-utils";
    crate2nix = { url = "github:kolloch/crate2nix"; flake = false; };
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = { self, nixpkgs, utils, crate2nix, rust-overlay }:
    utils.lib.eachSystem [ utils.lib.system.x86_64-linux ] (system:
      let
        name = "fexample";

        opkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlay ]; };
        rust = opkgs.rust-bin.nightly.latest.minimal;

        pkgs = nixpkgs.legacyPackages.${system} // {
          rustc = rust;
          cargo = rust;

          stdenv = opkgs.llvmPackages_13.stdenv;
          libcxx = opkgs.llvmPackages_13.libcxx;
        };

        inherit (import "${crate2nix}/tools.nix" { inherit pkgs; }) generatedCargoNix;
        project = import (generatedCargoNix {
          name = name;
          src = ./.;
        }) {
          inherit pkgs;

          defaultCrateOverrides = pkgs.defaultCrateOverrides // {
            librocksdb-sys = attrs: {
              LIBCLANG_PATH = "${pkgs.llvmPackages_13.libclang.lib}/lib";
              CARGO_CFG_TARGET_FEATURE = "";

              nativeBuildInputs = with pkgs; [ jemalloc zstd.dev clang_13 ];
              buildInputs = with pkgs; [ rustfmt ];
            };
          };
        };
      in {
        packages = {
          default = self.packages.${system}.foo;
          foo = project.workspaceMembers.foo.build;
          bar = project.workspaceMembers.bar.build;

          docker = let 
            bin = self.packages.${system}.foo;
          in pkgs.dockerTools.buildLayeredImage {
            name = "temp_container";
            tag = "latest";
            created = "now";

            contents = bin;
          };
        };

        apps.foo = utils.lib.mkApp { drv = self.packages.foo; };
        apps.bar = utils.lib.mkApp { drv = self.packages.bar; };
      });
}
