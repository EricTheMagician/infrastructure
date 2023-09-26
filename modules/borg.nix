{
  lib,
  ...
}: let
  borg_backup_paths = {
    options = {
      paths = lib.mkOption {
        type = lib.types.listOf lib.types.str;
      };
    };
  };
in {
  options.borg_backup_paths = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule borg_backup_paths);
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
  };
}
