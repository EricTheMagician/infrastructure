{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.keycloak;
in {
  imports = [
    ../../modules/nginx.nix
  ];
  options.keycloak = {
    domain = lib.mkOption {
      type = lib.types.str;
      default = "login.eyen.ca";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 1723;
    };
  };
  config = {
    sops.secrets.keycloak_database_password = {
      #owner = "keycloak";
    };
    services.keycloak = {
      enable = true;
      package = pkgs.keycloak;
      database = {
        type = "postgresql"; # this is already the default.
        createLocally = true;
        passwordFile = config.sops.secrets.keycloak_database_password.path;
      };
      settings = {
        http-host = "localhost"; # let the proxy decide
        http-port = cfg.port;
        proxy = "edge"; # allow to communicate over http.
        hostname = cfg.domain;
      };
    };
    services.nginx.virtualHosts."${cfg.domain}" = {
      useACMEHost = "eyen.ca";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${toString cfg.port}";
      };
    };
  };
}
