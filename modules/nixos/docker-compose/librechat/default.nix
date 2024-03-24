{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkOption mkEnableOption mkIf types;
  cfg = config.my.librechat;
  inherit (cfg) domain acme_host;
  env_file_path = config.sops.secrets."librechat/.env".path;
  source = inputs.libre-chat;
  settings = lib.generators.toYAML {} (import ./settings.nix);
  settings_yaml = pkgs.writeText "librechat.yaml" settings;
in {
  options.my.librechat = {
    enable = mkEnableOption "librechat";
    domain = mkOption {
      type = types.str;
      default = "librechat.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    port = mkOption {
      type = types.port;
      default = 15797;
    };
    datapath = mkOption {
      type = types.str;
      default = "/var/lib/librechat";
    };
  };

  config = mkIf cfg.enable {
    sops.secrets."librechat/.env" = {
      sopsFile = ../../../../secrets/librechat.env;
      format = "dotenv";
    };

    # Define the services
    virtualisation.arion.projects.libre-chat.settings.services = {
      # API service configuration
      api.service = {
        image = "ghcr.io/danny-avila/librechat-dev-api:latest";
        ports = [
          "127.0.0.1:${builtins.toString cfg.port}:3080"
        ];
        extra_hosts = [
          "host.docker.internal:host-gateway"
        ];
        environment = {
          HOST = "0.0.0.0";
          NODE_ENV = "production";
          MONGO_URI = "mongodb://mongodb:27017/LibreChat";
          MEILI_HOST = "http://meilisearch:7700";
        };
        env_file = [env_file_path];
        volumes = [
          "${cfg.datapath}/images:/app/client/public/images"
          "${settings_yaml}:/app/librechat.yaml"
        ];
        depends_on = ["mongodb"];
      };

      # Client service configuration
      client.service = {
        build = {
          context = source.outPath;
          dockerfile = "Dockerfile.multi";
          target = "prod-stage";
        };
        environment = {
          MONGO_URI = "mongodb://mongodb:27017/LibreChat";
        };
        ports = [
          "127.0.0.1:5664:80"
        ];
        volumes = [
          "${source}/client/nginx.conf:/etc/nginx/conf.d/default.conf"
        ];
        depends_on = ["api"];
      };

      # MongoDB service configuration
      mongodb.service = {
        image = "mongo";
        volumes = [
          "${cfg.datapath}/data-node:/data/db"
        ];
        command = "mongod --noauth";
      };

      # MeiliSearch service configuration
      meilisearch.service = {
        image = "getmeili/meilisearch:v1.0";
        environment = {
          MEILI_HOST = "http://meilisearch:7700";
          MEILI_NO_ANALYTICS = "true";
        };
        env_file = [env_file_path];
        volumes = [
          "${cfg.datapath}/meili_data:/meili_data"
        ];
      };
    };
    my.nginx.enable = true;
    my.backups.services.librechat = {paths = [cfg.datapath];};
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://127.0.0.1:${builtins.toString cfg.port}";
        proxyWebsockets = true;
      };
    };
  };
}
