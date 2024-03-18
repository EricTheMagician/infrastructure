{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.radarr;
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options.my.radarr = {
    enable = mkEnableOption "radarr";
    domain = mkOption {
      type = types.str;
      default = "radarr.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    read_write_dirs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of paths to read/write in radarr";
    };
  };
  config = mkIf cfg.enable {
    services.radarr = {
      enable = true;
      package = pkgs.unstable.radarr;
      user = "sabnzbd";
      group = "sabnzbd";
    };
    systemd.services.radarr.serviceConfig.ReadWritePaths = cfg.read_write_dirs;
    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      useACMEHost = cfg.acme_host;
      locations."/" = {
        proxyPass = "http://localhost:7878";
      };
    };
    my.nginx.enable = true;
    my.backups.services.radarr.paths = [config.services.radarr.dataDir];
  };
}
