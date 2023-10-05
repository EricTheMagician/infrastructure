{
  pkgs,
  lib,
  config,
  ...
}: let
  borg_backup_paths = {
    options = {
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };
  create_borg_backup_job = import ../functions/borg-job.nix;
in {
  imports = [
    ../modules/knownHosts.nix # add known hosts, specifically the storage box
  ];
  options.system_borg_backup_paths = lib.mkOption {
    #type = lib.types.attrsOf (lib.types.submodule borg_backup_paths);
    type = lib.types.listOf (lib.types.str);
    default = [];
  };
  # common sops secrets for borg backup
  config = {
    sops = {
      secrets.ping_key = {
        mode = "0400";
        sopsFile = ../secrets/healthchecks.yaml;
      };
      secrets.BORG_BACKUP_PASSWORD = {
        mode = "0400";
        sopsFile = ../secrets/borg-backup.yaml;
      };
      secrets.BORG_PRIVATE_KEY = {
        mode = "0400";
        sopsFile = ../secrets/borg-backup.yaml;
      };
    };

    services.borgbackup.jobs = lib.mkIf ((builtins.length config.system_borg_backup_paths) > 0) {
      system-backup =
        create_borg_backup_job {
          inherit config;
          name = "${config.networking.hostName}-system";
          paths = config.system_borg_backup_paths;
          startAt = "daily";
        }
        // {
          postHook = ''
            PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
            ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${config.networking.hostName}-system/$exitStatus" --silent
          '';
        };
    };
    systemd.timers = lib.mkIf ((builtins.length config.system_borg_backup_paths) > 0) {
      borgbackup-job-system-backup.timerConfig.RandomizedDelaySec = 3600 * 3;
    };
  };
}
