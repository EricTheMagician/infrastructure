{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types;
  cfg = config.my.authelia;
  secret_config = {sopsFile = ../../secrets/authelia.yaml;};
in {
  options.my.authelia = {
    enable = mkEnableOption "Enable Authelia";
    domain = mkOption {
      type = types.str;
      default = "auth.eyen.ca";
    };
    port = mkOption {
      type = types.port;
      default = 30557;
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    #my.postgresql.enable = true;
    #services.postgresql = {
    #  ensureDatabases = ["authelia-main"];
    #  ensureUsers = [
    #    {
    #      name = "authelia-main";
    #      ensureDBOwnership = true;
    #    }
    #  ];
    #};
    sops.secrets = {
      "authelia/jwt_secret" = secret_config;
      "authelia/session_secret" = secret_config;
      "authelia/settings" = secret_config;
    };
    services.redis.servers.authelia-main = {
      enable = true;
    };
    services.authelia.instances.main = {
      enable = true;
      secrets = {
        sessionSecretFile = "";
      };
      settings = {
        inherit (cfg) port;
        storage.local.path = "/var/lib/authelia/db.sqlite3";
        # copied from https://github.com/ibizaman/selfhostblocks/blob/3d3bc9dc389578d1a7f67bd3c8efdcfa2bf935e0/modules/blocks/authelia.nix#L226C1-L238C11
        session = {
          inherit (cfg) domain;
          name = "authelia_session";
          same_site = "lax";
          expiration = "1h";
          inactivity = "5m";
          remember_me_duration = "1M";
          redis = {
            host = config.services.redis.servers.authelia-main.unixSocket;
            port = 0;
          };
        };
      };
      settingsFiles = [
        config.sops.secrets."authelia/settings".path
      ];
    };
    services.nginx.virtualHosts.${cfg.domain} = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
    };
  };
}
