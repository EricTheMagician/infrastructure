{
  pkgs,
  lib,
  config,
  ...
}: let
  nextcloud_package = pkgs.nextcloud28;
  cfg = config.my.nextcloud;
  inherit (lib) mkOption mkEnableOption types mkIf;
in {
  options.my.nextcloud = {
    enable = mkEnableOption "Enable Nextcloud";
    domain = mkOption {
      type = types.str;
      default = "cloud.eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    sops.secrets."nextcloud/admin_password" = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    sops.secrets."nextcloud/db_password" = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    services.nextcloud = {
      enable = true;
      appstoreEnable = true;
      autoUpdateApps.enable = true;
      hostName = cfg.domain;
      https = true;
      maxUploadSize = "32G";
      caching.redis = true;
      configureRedis = true;
      config = {
        adminuser = "admin";
        adminpassFile = config.sops.secrets."nextcloud/admin_password".path;
        dbtype = "pgsql";
        dbpassFile = config.sops.secrets."nextcloud/db_password".path;
        defaultPhoneRegion = "CA";
      };
      database.createLocally = true;

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
    my.backups.services.nextcloud = {
      paths = [config.services.nextcloud.datadir];
      postgres_databases = [config.services.nextcloud.config.dbname];
    };

    services.nginx.virtualHosts.${cfg.domain} = {
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
          inherit (cfg) domain;
          server_name = cfg.domain;
          extra_params = "--o:ssl.enable=false --o:ssl.termination=true";
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
  };
}
