{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.sabnzbd;
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options.my.sabnzbd = {
    enable = mkEnableOption "sabnzbd";
    domain = mkOption {
      type = types.str;
      default = "sabnzbd.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    read_write_dirs = mkOption {
      type = types.listOf types.str;
      default = [];
      description = "List of paths to read/write in sabnzbd";
    };
  };
  config = mkIf cfg.enable {
    services.sabnzbd = {
      enable = true;
      configFile = "/var/lib/sabnzbd/sabnzbd.ini";
      package = pkgs.unstable.sabnzbd;
      user = "sabnzbd";
      group = "sabnzbd";
    };
    systemd.services.sabnzbd.serviceConfig.WorkingDirectory = "/var/lib/sabnzbd";
    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      useACMEHost = cfg.acme_host;
      locations."/" = {
        proxyPass = "http://localhost:8080";
      };
    };
    my.nginx.enable = true;
    my.backups.services.sabnzbd.paths = [config.services.sabnzbd.configFile];
  };
}
