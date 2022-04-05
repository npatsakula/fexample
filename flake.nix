{
  inputs = {
    naersk.url = "github:nmattia/naersk/master";
    utils.url = "github:numtide/flake-utils";
    mozillapkgs = {
      url = "github:mozilla/nixpkgs-mozilla";
      flake = false;
    };
  };
  outputs = { self, nixpkgs, utils, naersk, mozillapkgs }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs { inherit system; };
        mozilla = pkgs.callPackage (mozillapkgs + "/package-set.nix") {};

        rust = (mozilla.rustChannelOf {
          channel = "1.59.0";
          sha256 = "4IUZZWXHBBxcwRuQm9ekOwzc0oNqH/9NkI1ejW7KajU=";
        }).rust;

        naersk-lib = pkgs.callPackage naersk {
          cargo = rust;
          rustc = rust;
        };

        # Хотелось бы указать эту зависимость непосредственно
        # для rocksdb, а не для всего софта.
        nativeBuildInputs = with pkgs; [
          llvmPackages_13.libclang
          clang_13
          # Вот это добро не работает, в итоге всё равно пытается
          # собраться силами GCC. Как задать stdenv не сильно понятно:(
          llvmPackages_13.llvm.cc
        ];
      in {
        defaultPackage = naersk-lib.buildPackage {
          root = ./.;
          pname = "fexample";
          # Вот эта часть выглядит достаточно дичёво, как переписать её по-другому
          # не очень понятно.
          preBuild = ''
            export LIBCLANG_PATH="${pkgs.llvmPackages_13.libclang.lib}/lib";
            export CLANG_PATH="${pkgs.clang_13}/bin/clang";
          '';
        };

        defaultApp = utils.lib.mkApp {
            drv = self.defaultPackage."${system}";
        };
      });
}
