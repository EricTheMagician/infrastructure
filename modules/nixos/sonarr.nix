{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.sonarr;
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options.my.sonarr = {
    enable = mkEnableOption "sonarr";
    domain = mkOption {
      type = types.str;
      default = "sonarr.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    read_write_dirs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of paths to read/write in sonarr";
    };
  };
  config = mkIf cfg.enable {
    services.sonarr = {
      enable = true;
      package = pkgs.unstable.sonarr;
      user = "sabnzbd";
      group = "sabnzbd";
    };
    systemd.services.sonarr.serviceConfig.ReadWritePaths = cfg.read_write_dirs;
    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      useACMEHost = cfg.acme_host;
      locations."/" = {
        proxyPass = "http://localhost:8989";
      };
    };
    my.nginx.enable = true;
    my.backups.services.sonarr.paths = [config.services.sonarr.dataDir];
  };
}
