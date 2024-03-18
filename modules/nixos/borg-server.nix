{
  config,
  lib,
  ...
}: let
  cfg = config.my.borg-server;
  inherit (lib) mkOption mkEnableOption mkIf types;
in {
  options.my.borg-server = {
    enable = mkEnableOption "borg-server";
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of authorized public keys";
    };
  };

  config = mkIf cfg.enable {
    services.borgbackup.repos.main = {
      # user = "borg";
      # quota = "2T";
      # path = "/var/lib/borgbackup";
      inherit (cfg) authorizedKeys;
      allowSubRepos = true;
    };
  };
}
