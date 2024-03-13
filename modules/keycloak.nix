{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.my.keycloak;
  inherit (lib) mkEnableOption mkOption types mkIf;
in {
  options.my.keycloak = {
    enable = mkEnableOption "keycloak";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "login.eyen.ca";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1723;
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets."keycloak/database_password" = {};
    services.keycloak = {
      enable = true;
      package = pkgs.keycloak;
      database = {
        type = "postgresql"; # this is already the default.
        createLocally = true;
        passwordFile = config.sops.secrets."keycloak/database_password".path;
      };
      settings = {
        http-host = "localhost"; # let the proxy decide
        http-port = cfg.port;
        proxy = "edge"; # allow to communicate over http.
        hostname = cfg.domain;
      };
    };
    services.nginx.virtualHosts."${cfg.domain}" = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString cfg.port}";
      };
    };
    my.backups.services.keycloak.postgres_databases = ["keycloak"];
  };
}
