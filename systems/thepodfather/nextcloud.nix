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
      passwordFile = config.sops.secrets.NEXTCLOUD_DB_PASSWORD.path;
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
      passwordFile = config.sops.secrets.ONLYOFFICE_DB_PASSWORD.path;
      wantedBy = ["onlyoffice-docservice.service"];
      beforeServices = ["onlyoffice-docservice.service"];
      inherit config;
      inherit (pkgs) lib;
    };
  create_database = lib.recursiveUpdate create_nextcloud_database create_onlyoffice_database;
in
  lib.recursiveUpdate
  {
    sops.secrets.NEXTCLOUD_ADMIN_PASSWORD = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    sops.secrets.NEXTCLOUD_DB_PASSWORD = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    sops.secrets.ONLYOFFICE_DB_PASSWORD = {
      owner = "onlyoffice";
      group = "onlyoffice";
    };
    sops.secrets.ONLYOFFICE_SECRET = {
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
        adminpassFile = config.sops.secrets.NEXTCLOUD_ADMIN_PASSWORD.path;
        dbtype = "pgsql";
        dbpassFile = config.sops.secrets.NEXTCLOUD_DB_PASSWORD.path;
        defaultPhoneRegion = "CA";
      };
      phpOptions."opcache.interned_strings_buffer" = "23";
      package = nextcloud_package;
      #extraOptions = {
      #  memories.exiftool = "${pkgs.exiftool}/bin/exiftool";
      #};
    };
    services.postgresqlBackup.databases = [config.services.nextcloud.config.dbname];
    system_borg_backup_paths = [config.services.nextcloud.datadir];
    services.nginx.virtualHosts."cloud.eyen.ca" = {
      useACMEHost = "eyen.ca";
      forceSSL = true;
    };
    services.onlyoffice = {
      package = pkgs.unstable.onlyoffice-documentserver;
      enable = true;
      hostname = "office.eyen.ca";
      jwtSecretFile = config.sops.secrets.ONLYOFFICE_SECRET.path;
      postgresPasswordFile = config.sops.secrets.ONLYOFFICE_DB_PASSWORD.path;
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
  create_database
