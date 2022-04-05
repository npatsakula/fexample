{
  inputs = {
    naersk.url = "github:nmattia/naersk/master";
    utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
  };
  outputs = { self, nixpkgs, utils, naersk, rust-overlay }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; overlays = [ rust-overlay.overlay ]; };
        rust = pkgs.rust-bin.stable.latest.default;

        naersk-lib = pkgs.callPackage naersk {
          cargo = rust;
          rustc = rust;
          stdenv = pkgs.llvmPackages_13.stdenv;
        };

      in {
        defaultPackage = naersk-lib.buildPackage rec {
          root = ./.;
          pname = "fexample";
          version = "0.1.0";

          override = x: (
              # if x.name == "${pname}-deps-${version}" then
              x // { LIBCLANG_PATH = "${pkgs.llvmPackages_13.libclang.lib}/lib"; }
              # else x
            );
        };

        defaultApp = utils.lib.mkApp {
            drv = self.defaultPackage."${system}";
        };
      });
}
