{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mkIf types mkMerge;
  system_backup_enabled = (builtins.length config.my.backups.paths) > 0;
  cfg = config.my.backups;
in {
  imports = [
    ./helpers/borg_backup.nix
  ];
  options.my.backups = {
    paths = mkOption {
      #type = lib.types.attrsOf (lib.types.submodule borg_backup_paths);
      type = types.listOf types.str;
      default = [];
      #description = "List of paths to backup. This uses the system repository";
    };

    services = mkOption {
      default = {};
      description = "Set of services to backup";

      #https://nixos.org/manual/nixos/stable/#ex-submodule-attrsof-declaration
      # this will let me have my.backups.services.acme = {path = ...};
      type = with types;
        attrsOf (submodule {
          options = {
            paths = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
            };
            patterns = mkOption {
              type = types.listOf types.str;
              default = [];
            };
            mysql_databases = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
            };
            postgres_databases = mkOption {
              type = types.nullOr (types.listOf types.str);
              default = null;
            };
            startAt = mkOption {
              type = types.str;
              default = "daily";
            };
            keep = {
              within = mkOption {
                type = types.nullOr types.str;
                default = "1d";
                description = "Keep all archives from the last day";
              };
              daily = mkOption {
                type = types.nullOr types.ints.positive;
                default = 7;
              };
              weekly = mkOption {
                type = types.nullOr types.ints.positive;
                default = 4;
              };
              monthly = mkOption {
                type = types.nullOr types.ints.positive;
                default = 12;
              };
            };
          };
        });
    };

    add_scripts = mkOption {
      type = types.bool;
      description = "Add my custom scripts to my backups. To change which repository we are looking at, set the evar HOSTNAME to the intended machine";
      default = false;
    };
  };
  # common sops secrets for borg backup
  config = mkMerge [
    # configure the needed secrets
    (mkIf (system_backup_enabled || cfg.add_scripts) {
      sops.secrets = {
        healthchecks_api_key = {
          mode = "0400";
          sopsFile = ../secrets/healthchecks.yaml;
        };
        ping_key = {
          mode = "0400";
          sopsFile = ../secrets/healthchecks.yaml;
        };
        "borg/password" = {
          mode = "0400";
          sopsFile = ../secrets/borg-backup.yaml;
        };
        "borg/private_key" = {
          mode = "0400";
          sopsFile = ../secrets/borg-backup.yaml;
        };
      };
    })

    # configure the system backup service
    (mkIf system_backup_enabled {
      my.backups.services.system = {
        inherit (cfg) paths;
        keep = {
          within = "7d"; # Keep all archives from the last day
          daily = 14;
          weekly = 8;
          monthly = 12; # Keep at least one archive for each month
        };
      };
    })
    #confiure the scripts
    (
      mkIf cfg.add_scripts {
        environment.systemPackages = let
          # things that are generally needed when using borg
          borg_script_setup = ''
            STORAGE_URL=u322294.your-storagebox.de
            HOSTNAME=`hostname`
            export BORG_REPO="ssh://u322294@$STORAGE_URL:23/./$HOSTNAME"
            export BORG_RSH="ssh -i /run/secrets/BORG_PRIVATE_KEY"
            export BORG_PASSPHRASE="`sudo cat /run/secrets/BORG_BACKUP_PASSWORD`"
            cd /
          '';
        in
          mkIf config.my.backups.addScripts [
            (pkgs.writeShellScriptBin "borg-mount" ''
              ${borg_script_setup}
              borg mount $BORG_REPO $@
            '')
            (pkgs.writeShellScriptBin "borg-extract" ''
              ${borg_script_setup}
              borg extract $@
            '')
            (pkgs.writeShellScriptBin "borg-list" ''
              ${borg_script_setup}
              borg list $@
            '')
          ];
      }
    )
  ];
}
