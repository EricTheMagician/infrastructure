{
  pkgs,
  lib,
  config,
  ...
}: let
  backup_enabled = (builtins.length config.my.backup_paths) > 0;
  create_borg_backup_job = import ../functions/borg-job.nix;
in {
  imports = [
    ../modules/knownHosts.nix # add known hosts, specifically the storage box
  ];
  options.my.backup_paths = lib.mkOption {
    #type = lib.types.attrsOf (lib.types.submodule borg_backup_paths);
    type = lib.types.listOf lib.types.str;
    default = [];
  };
  # common sops secrets for borg backup
  config = lib.mkIf backup_enabled {
    sops = {
      secrets = {
        ping_key = {
          mode = "0400";
          sopsFile = ../secrets/healthchecks.yaml;
        };
        BORG_BACKUP_PASSWORD = {
          mode = "0400";
          sopsFile = ../secrets/borg-backup.yaml;
        };
        BORG_PRIVATE_KEY = {
          mode = "0400";
          sopsFile = ../secrets/borg-backup.yaml;
        };
      };
    };

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
    in [
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
    services.borgbackup.jobs = {
      system-backup =
        create_borg_backup_job {
          inherit config;
          name = "${config.networking.hostName}-system";
          paths = config.my.backup_paths;
          startAt = "daily";
        }
        // {
          postHook = ''
            PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
            ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${config.networking.hostName}-system/$exitStatus" --silent
          '';
        };
    };
    systemd.timers = {
      borgbackup-job-system-backup.timerConfig.RandomizedDelaySec = 3600 * 3;
    };
  };
}
