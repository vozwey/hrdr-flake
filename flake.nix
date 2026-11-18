{
  description = "Home Manager module for hrdr";

  # Tracks the default branch. No rev or hash is written here; the lock file
  # holds the commit, and `nix flake update hrdr` moves it to the latest.
  inputs.hrdr = {
    url = "github:kryptic-sh/hrdr";
    flake = false;
  };

  outputs = { self, hrdr }: {
    homeManagerModules.default = { config, lib, pkgs, ... }:
      let
        cfg = config.programs.hrdr;
        toml = pkgs.formats.toml { };
      in
      {
        options.programs.hrdr = {
          enable = lib.mkEnableOption "hrdr, a terminal coding agent";

          package = lib.mkOption {
            type = lib.types.package;
            description = "The hrdr package, built from the flake input.";
            default = pkgs.rustPlatform.buildRustPackage {
              pname = "hrdr";
              version = (lib.importTOML "${hrdr}/Cargo.toml").workspace.package.version;
              src = hrdr;
              cargoLock.lockFile = "${hrdr}/Cargo.lock";
              cargoBuildFlags = [ "-p" "hrdr" ];
              doCheck = false;
              meta = {
                description = "Terminal coding agent for OpenAI-compatible models";
                license = lib.licenses.mit;
                mainProgram = "hrdr";
              };
            };
          };

          settings = lib.mkOption {
            type = toml.type;
            default = { };
            description = ''
              Contents of {file}`~/.config/hrdr/config.toml`, written 1:1 as TOML.
              When empty, no file is created and hrdr manages its own config.
            '';
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
