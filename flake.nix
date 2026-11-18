{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    hrdr = {
      url = "github:kryptic-sh/hrdr";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, hrdr }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];
      forAll = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAll (system:
        let pkgs = nixpkgs.legacyPackages.${system}; in {
          default = pkgs.rustPlatform.buildRustPackage {
            pname = "hrdr";
            version = (pkgs.lib.importTOML "${hrdr}/Cargo.toml").workspace.package.version;
            src = hrdr;
            cargoLock.lockFile = "${hrdr}/Cargo.lock";
            cargoBuildFlags = [ "-p" "hrdr" ];
            doCheck = false;
            meta.mainProgram = "hrdr";
          };
        });

      homeManagerModules.default = { config, lib, pkgs, ... }:
        let
          cfg = config.programs.hrdr;
          toml = pkgs.formats.toml { };
        in
        {
          options.programs.hrdr = {
            enable = lib.mkEnableOption "hrdr";
            package = lib.mkOption {
              type = lib.types.package;
              default = self.packages.${pkgs.stdenv.hostPlatform.system}.default;
            };
            settings = lib.mkOption {
              type = toml.type;
              default = { };
            };
          };

          config = lib.mkIf cfg.enable {
            home.packages = [ cfg.package ];
            xdg.configFile."hrdr/config.toml" = lib.mkIf (cfg.settings != { }) {
              source = toml.generate "hrdr-config.toml" cfg.settings;
            };
          };
        };
    };
}
