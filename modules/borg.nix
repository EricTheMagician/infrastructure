{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  # common sops secrets for borg backup
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
}
