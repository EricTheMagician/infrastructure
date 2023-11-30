{
  pkgs,
  lib,
  config,
  ...
}: let
  nextcloud_package = pkgs.unstable.nextcloud27;
  create_nextcloud_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "nextcloud";
      user_name = "nextcloud";
      passwordFile = config.sops.secrets."nextcloud/db_password".path;
      wantedBy = ["nextcloud-setup.service"];
      beforeServices = ["nextcloud-setup.service"];
      inherit config;
      inherit (pkgs) lib;
    };
  create_onlyoffice_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "onlyoffice";
      user_name = "onlyoffice";
      passwordFile = config.sops.secrets."onlyoffice/db_password".path;
      wantedBy = ["onlyoffice-docservice.service"];
      beforeServices = ["onlyoffice-docservice.service"];
      inherit config;
      inherit (pkgs) lib;
    };
in
  lib.mkMerge [
    create_nextcloud_database
    #create_onlyoffice_database
    {
      sops.secrets."nextcloud/admin_password" = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      sops.secrets."nextcloud/db_password" = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      #sops.secrets."onlyoffice/db_password" = {
      #  owner = "onlyoffice";
      #  group = "onlyoffice";
      #};
      #sops.secrets."onlyoffice/secret" = {
      #  owner = "onlyoffice";
      #  group = "onlyoffice";
      #};
      services.nextcloud = {
        enable = true;

        appstoreEnable = true;
        autoUpdateApps.enable = true;
        hostName = "cloud.eyen.ca";
        https = true;
        maxUploadSize = "10G";
        caching.redis = true;
        configureRedis = true;
        config = {
          adminuser = "admin";
          adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
          dbtype = "pgsql";
          dbpassFile = config.sops.secrets."nextcloud/db_password".path;
          defaultPhoneRegion = "CA";
        };
        phpOptions."opcache.interned_strings_buffer" = "23";
        package = nextcloud_package;
        #extraOptions = {
        #  memories.exiftool = "${pkgs.exiftool}/bin/exiftool";
        #};
      };
      services.postgresqlBackup.databases = [
        config.services.nextcloud.config.dbname
        #config.services.onlyoffice.postgresName
      ];
      system_borg_backup_paths = [config.services.nextcloud.datadir];
      services.nginx.virtualHosts."cloud.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
      };

      #services.onlyoffice = {
      #  package = pkgs.unstable.onlyoffice-documentserver;
      #  enable = true;
      #  hostname = "office.eyen.ca";
      #  jwtSecretFile = config.sops.secrets."onlyoffice/secret".path;
      #  postgresPasswordFile = config.sops.secrets."onlyoffice/db_password".path;
      #};

      virtualisation.oci-containers = {
        # Since 22.05, the default driver is podman but it doesn't work
        # with podman. It would however be nice to switch to podman.
        backend = "docker";
        containers.collabora = {
          image = "collabora/code";
          #imageFile = pkgs.dockerTools.pullImage {
          #  imageName = "collabora/code";
          #  imageDigest = "sha256:32c05e2d10450875eb153be11bfb7683fa0db95746e1f59d8c2fc3d988b45445";
          #  sha256 = "sha256-laQJldVH8ri54lFecJ26tGdlOGtnb+w7Bb+GJ/spzr8=";
          #};
          ports = ["9980:9980"];
          environment = {
            domain = "cloud.eyen.ca";
            extra_params = "--o:ssl.enable=true --o:ssl.termination=true";
          };
          extraOptions = [
            "--cap-add"
            "SYS_ADMIN"
            "--pull=always"
          ];
        };
      };

      services.nginx.virtualHosts."office.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        #  locations = {
        #    # static files
        #    #"/" = {
        #    #  proxyPass = "http://127.0.0.1:${builtins.toString config.services.onlyoffice.port}";
        #    #};
        #  };

        locations = {
          # https://sdk.collaboraonline.com/docs/installation/Proxy_settings.html#reverse-proxy-with-nginx-webserver
          # static files
          "^~ /browser" = {
            priority = 0;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };
          # WOPI discovery URL
          "^~ /hosting/discovery" = {
            priority = 100;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };

          # Capabilities
          "^~ /hosting/capabilities" = {
            priority = 200;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };

          # download, presentation, image upload and websocket
          "~ ^/cool/(.*)/ws$" = {
            priority = 300;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
              proxy_set_header Host $host;
              proxy_read_timeout 36000s;
            '';
          };

          # download, presentation and image upload
          "~ ^/(c|l)ool" = {
            priority = 400;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Host $host;
            '';
          };

          # Admin Console websocket
          "^~ /cool/adminws" = {
            priority = 500;
            proxyPass = "http://localhost:9980";
            extraConfig = ''
              proxy_set_header Upgrade $http_upgrade;
              proxy_set_header Connection "Upgrade";
              proxy_set_header Host $host;
              proxy_read_timeout 36000s;
            '';
          };
        };
      };

      services.phpfpm.pools.nextcloud = {
        phpEnv = {
          #LD_LIBRARY_PATH = config.environment.environment.NIX_LD_LIBRARY_PATH;
          inherit (config.environment.variables) NIX_LD_LIBRARY_PATH;
          inherit (config.environment.variables) NIX_LD;
        };
      };

      environment.systemPackages = with pkgs; [
        nextcloud_package
        # for nextcloud memories
        unstable.exiftool
        unstable.exif
        ffmpeg_6
        nodejs_20
        unstable.perl536Packages.ImageExifTool
      ];
    }
  ]
