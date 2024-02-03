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
  };

  config = mkIf cfg.enable {
    my.nginx.enable = true;
    services.audiobookshelf = {
      enable = true;
    };
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString config.services.audiobookshelf.port}";
      };
    };
  };
}
