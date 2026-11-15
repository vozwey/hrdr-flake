{
  description = "Coding harness";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    hrdr-src = {
      url = "github:kryptic-sh/hrdr";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, hrdr-src }: {
    homeManagerModules.default = { pkgs, ... }: {
      home.packages = [
        (pkgs.rustPlatform.buildRustPackage {
          pname = "hrdr";
          version = (builtins.fromTOML (builtins.readFile "${hrdr-src}/Cargo.toml")).workspace.package.version;
          src = hrdr-src;

          cargoLock.lockFile = "${hrdr-src}/Cargo.lock";
          cargoBuildFlags = [ "-p" "hrdr" ];

          nativeBuildInputs = [ pkgs.git ];

          doCheck = false;

          meta = {
            description = "Coding harness";
            license = pkgs.lib.licenses.mit;
            mainProgram = "hrdr";
            platforms = pkgs.lib.platforms.linux;
          };
        })
      ];

      xdg.configFile."hrdr/config.toml".source = (pkgs.formats.toml { }).generate "hrdr-config.toml" { };
    };
  };
}
