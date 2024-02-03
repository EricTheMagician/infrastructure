{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.my.audiobookshelf;
  inherit (cfg) domain acme_host;
in {
  options.my.audiobookshelf = {
    enable = mkEnableOption "audiobookshelf";
    domain = mkOption {
      type = types.str;
      default = "audiobookshelf.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    port = mkOption {
      type = types.port;
      default = 33748;
    };
  };

  config = mkIf cfg.enable {
    my.nginx.enable = true;
    my.backups.paths = ["/var/lib/audiobookshelf/metadata/backups"];
    services.audiobookshelf = {
      inherit (cfg) port;
      enable = true;
      package = pkgs.unstable.audiobookshelf;
    };
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString config.services.audiobookshelf.port}";
        proxyWebsockets = true;
      };
    };
  };
}
