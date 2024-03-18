{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.jellyfin;
  inherit (cfg) domain acme_host;
  inherit (lib) mkIf mkOption mkEnableOption types;
in {
  options.my.jellyfin = {
    enable = mkEnableOption "jellyfin";
    domain = mkOption {
      type = types.str;
      default = "jellyfin.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    my.nginx.enable = true;
    services.jellyfin = {
      enable = true;
      package = pkgs.unstable.jellyfin;
    };
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:8096";
      };
    };
    my.backups.services.jellyfin.paths = ["/var/lib/jellyfin"];
  };
}
