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
    create_onlyoffice_database
    {
      sops.secrets."nextcloud/admin_password" = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      sops.secrets."nextcloud/db_password" = {
        owner = "nextcloud";
        group = "nextcloud";
      };
      sops.secrets."onlyoffice/db_password" = {
        owner = "onlyoffice";
        group = "onlyoffice";
      };
      sops.secrets."onlyoffice/secret" = {
        owner = "onlyoffice";
        group = "onlyoffice";
      };
      services.nextcloud = {
        appstoreEnable = true;
        enable = true;
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
      services.postgresqlBackup.databases = [config.services.nextcloud.config.dbname config.services.onlyoffice.postgresName];
      system_borg_backup_paths = [config.services.nextcloud.datadir];
      services.nginx.virtualHosts."cloud.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
      };
      services.onlyoffice = {
        package = pkgs.unstable.onlyoffice-documentserver;
        enable = true;
        hostname = "office.eyen.ca";
        jwtSecretFile = config.sops.secrets."onlyoffice/secret".path;
        postgresPasswordFile = config.sops.secrets."onlyoffice/db_password".path;
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
