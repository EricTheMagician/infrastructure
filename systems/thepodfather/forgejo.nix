{
  pkgs,
  lib,
  config,
  ...
}: let
  domain = "git.eyen.ca";
  create_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "forgejo";
      user_name = "forgejo";
      passwordFile = config.sops.secrets."forgejo/database_password".path;
      wantedBy = ["forgejo.service"];
      inherit config;
      inherit lib;
    };
in
  lib.recursiveUpdate
  {
    imports = [
      ../../modules/nginx.nix
      ../../modules/borg.nix
    ];
    sops.secrets = {
      "forgejo/database_password" = {
        owner = config.services.forgejo.user;
        inherit (config.services.forgejo) group;
        restartUnits = ["forgejo.service"];
      };
      "forgejo/secret_key" = {
        owner = config.services.forgejo.user;
        inherit (config.services.forgejo) group;
        restartUnits = ["forgejo.service"];
        path = "${config.services.forgejo.customDir}/conf/secret_key";
      };
      "forgejo/internal_token" = {
        owner = config.services.forgejo.user;
        inherit (config.services.forgejo) group;
        restartUnits = ["forgejo.service"];
        path = "${config.services.forgejo.customDir}/conf/internal_token";
      };
      "forgejo/oauth_jwt_secret" = {
        owner = config.services.forgejo.user;
        inherit (config.services.forgejo) group;
        restartUnits = ["forgejo.service"];
        path = "${config.services.forgejo.customDir}/conf/oauth2_jwt_secret";
      };
      "forgejo/lfs_jwt_secret" = {
        owner = config.services.forgejo.user;
        inherit (config.services.forgejo) group;
        restartUnits = ["forgejo.service"];
        path = "${config.services.forgejo.customDir}/conf/lfs_jwt_secret";
      };
    };

    services = {
      forgejo = {
        enable = true;
        package = pkgs.unstable.forgejo;
        database = {
          type = "postgres";
          passwordFile = config.sops.secrets."forgejo/database_password".path;
          host = "localhost";
          #socket = null;
          createDatabase = false;
        };
        dump = {
          enable = false;
          type = "tar.xz";
          interval = "daily";
        };
        lfs = {
          enable = true;
        };
        settings = {
          actions.ENABLED = "true";
          server = {
            HTTP_ADDR = "localhost";
            HTTP_PORT = 57779;
            DOMAIN = domain;
            ROOT_URL = "https://${domain}";
          };
          session = {COOKIE_SECURE = true;};
        };
      };

      nginx.virtualHosts.${domain} = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${builtins.toString config.services.forgejo.settings.server.HTTP_PORT}";
        };
      };
    };

    networking.firewall.allowedTCPPorts = [config.services.forgejo.settings.server.SSH_PORT];

    system_borg_backup_paths = [config.services.forgejo.repositoryRoot config.services.forgejo.customDir config.services.forgejo.lfs.contentDir];
  }
  create_database
