{
  config,
  lib,
  ...
}: let
  data_path = "/mnt/unraid/immich";
  upload_path = "${data_path}/upload";
  env_file = config.sops.secrets."immich/env_file".path;
  immich_sops = {
    sopsFile = ../../../secrets/immich.yaml;
    mode = "0400";
  };
  redis_socket = config.services.redis.servers.immich.unixSocket;
  db_socket = "/run/postgresql";
  immich_environment = {
    REDIS_SOCKET = redis_socket;
    DB_HOSTNAME = config.my.immich.database.hostname;
  };
  immich_volumes = [
    "${upload_path}:/usr/src/app/upload"
    "/etc/localtime:/etc/localtime:ro"
    "${redis_socket}:${redis_socket}"
    "${db_socket}:${db_socket}"
  ];

  create_database = import ../../../functions/create_postgresql_db.nix {
    name = "immich";
    user_name = "immich";
    passwordFile = config.sops.secrets."immich/db_password".path;
    wantedBy = ["arion-immich.service"];
    inherit config lib;
  };
  cfg = config.my.immich;
  inherit (lib) mkOption mkEnableOption types mkIf mkMerge;
  #create_database;
in {
  options.my.immich = {
    enable = mkEnableOption "Enable Immich";
    domain = mkOption {
      type = types.str;
      default = "immich.eyen.ca";
    };
    port = mkOption {
      type = types.port;
      default = 2283;
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
    database = {
      hostname = mkOption {
        type = types.str;
        default = "localhost";
      };
    };
  };
  config = mkMerge [
    (mkIf cfg.enable create_database)
    (mkIf cfg.enable {
      sops.secrets = {
        "immich/env_file" = immich_sops;
        "immich/db_password" = immich_sops;
      };

      services.redis.servers.immich = {
        enable = true;
      };

      systemd.services.arion-immich = {
        after = ["redis-immich.service" "postgresql.service"];
      };

      virtualisation.arion.projects.immich.settings.docker-compose.volumes = {
        model-cache = {};
      };
      virtualisation.arion.projects.immich.settings.services = {
        immich-server.service = {
          container_name = "immich_server";
          image = "ghcr.io/immich-app/immich-server:release";
          command = ["start.sh" "immich"];
          ports = [
            "${builtins.toString cfg.port}:3001"
          ];
          environment = immich_environment;
          volumes =
            immich_volumes;
          env_file = [env_file];
          restart = "unless-stopped";
        };

        immich-microservices.service = {
          container_name = "immich_microservices";
          image = "ghcr.io/immich-app/immich-server:release";
          # extends =
          #   file = hwaccel.yml
          #   service = hwaccel
          command = ["start.sh" "microservices"];
          volumes = immich_volumes;
          environment = immich_environment;
          env_file = [env_file];
          restart = "unless-stopped";
        };

        immich-machine-learning.service = {
          container_name = "immich_machine_learning";
          image = "ghcr.io/immich-app/immich-machine-learning:release";
          volumes = [
            "model-cache:/cache"
          ];
          env_file = [env_file];
          restart = "unless-stopped";
        };
      };

      services.nginx.virtualHosts.${cfg.domain} = {
        useACMEHost = cfg.acme_host;
        forceSSL = true;
        locations."/".proxyPass = "http://localhost:${builtins.toString cfg.port}";
      };
      my.backups.services.immich = {
        paths = [data_path];
        postgres_databases = ["immich"];
      };
    })
  ];
}
