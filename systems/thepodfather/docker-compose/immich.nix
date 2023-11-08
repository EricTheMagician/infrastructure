{
  config,
  inputs,
  pkgs,
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
  db_socket = "/run/postgresql/.s.PGSQL.5432";
  immich_environment = {
    REDIS_SOCKET = redis_socket;
    DB_HOSTNAME = "100.64.0.18";
    TYPESENSE_HOST = "100.64.0.18";
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
    inherit config;
    inherit (pkgs) lib;
  };
in
  lib.recursiveUpdate {
    imports = [
      "${inputs.nixpkgs-unstable}/nixos/modules/services/search/typesense.nix"
    ];
    sops.secrets = {
      "immich/typesense_api" = {
        sopsFile = ../../../secrets/immich.yaml;
        mode = "0444";
      };
      "immich/env_file" = immich_sops;
      "immich/db_password" = immich_sops;
    };

    services.redis.servers.immich = {
      enable = true;
    };

    services.typesense = {
      enable = true;
      apiKeyFile = config.sops.secrets."immich/typesense_api".path;
      package = pkgs.unstable.typesense;
      settings = {server = {api-address = "0.0.0.0";};};
    };
    virtualisation.arion.projects.immich.settings.docker-compose.volumes = {
      model-cache = {};
    };
    virtualisation.arion.projects.immich.settings.services = {
      immich-server.service = {
        container_name = "immich_server";
        image = "ghcr.io/immich-app/immich-server:release";
        command = ["start.sh" "immich"];
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
      immich-web.service = {
        container_name = "immich_web";
        image = "ghcr.io/immich-app/immich-web:release";
        environment = immich_environment;
        env_file = [env_file];
        restart = "unless-stopped";
      };

      #typesense = {
      #  container_name = "immich_typesense";
      #  image = "typesense/typesense:0.24.1@sha256:9bcff2b829f12074426ca044b56160ca9d777a0c488303469143dd9f8259d4dd";
      #  env_file = [typesense_env];
      #  #environment =
      #  #  - TYPESENSE_API_KEY=${TYPESENSE_API_KEY}
      #  #  - TYPESENSE_DATA_DIR=/data
      #  #  # remove this to get debug messages
      #  #  - GLOG_minloglevel=1
      #  volumes = [
      #    "tsdata:/data"
      #  ];
      #  restart = "unless-stopped";
      #};
      # redis ={
      #   container_name = "immich_redis";
      #   image = "redis:6.2-alpine@sha256:70a7a5b641117670beae0d80658430853896b5ef269ccf00d1827427e3263fa3";
      #   restart = "unless-stopped";
      #   };

      # database =
      #   container_name = immich_postgres
      #   image = postgres:14-alpine@sha256:28407a9961e76f2d285dc6991e8e48893503cc3836a4755bbc2d40bcc272a441
      #   env_file =
      #     - .env
      #   environment =
      #     POSTGRES_PASSWORD = ${DB_PASSWORD}
      #     POSTGRES_USER = ${DB_USERNAME}
      #     POSTGRES_DB = ${DB_DATABASE_NAME}
      #   volumes =
      #     - pgdata:/var/lib/postgresql/data
      #   restart = unless-stopped

      immich-proxy.service = {
        container_name = "immich_proxy";
        image = "ghcr.io/immich-app/immich-proxy:release";
        ports = [
          "2283:8080"
        ];
        depends_on = [
          "immich-server"
          "immich-web"
        ];
        restart = "unless-stopped";
      };
    };

    services.nginx.virtualHosts."immich.eyen.ca" = {
      useACMEHost = "eyen.ca";
      forceSSL = true;
      locations."/".proxyPass = "http://localhost:2283";
    };
  }
  create_database
