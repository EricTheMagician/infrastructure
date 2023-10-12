{
  pkgs,
  config,
  ...
}: let
  nextcloud_package = pkgs.unstable.nextcloud27;
  create_database =
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
in
  {
    imports = [
      ../../modules/borg.nix
    ];
    sops.secrets.NEXTCLOUD_ADMIN_PASSWORD = {
      owner = "nextcloud";
      group = "nextcloud";
    };
    sops.secrets.NEXTCLOUD_DB_PASSWORD = {
      owner = "nextcloud";
      group = "nextcloud";
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
    };
    environment.systemPackages = [nextcloud_package];
    services.postgresqlBackup.databases = [config.services.nextcloud.config.dbname];
    system_borg_backup_paths = [config.services.nextcloud.datadir];
    services.nginx.virtualHosts."cloud.eyen.ca" = {
      useACMEHost = "eyen.ca";
      forceSSL = true;
    };
  }
  // create_database
