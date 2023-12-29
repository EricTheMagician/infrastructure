{
  config,
  pkgs,
  lib,
  ...
}: let
  secret_config = {
    owner = "invidious";
    group = "invidious";
    restartUnits = ["invidious.service"];
  };
  create_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "invidious";
      user_name = "invidious";
      passwordFile = config.sops.secrets."invidious/db_password".path;
      wantedBy = ["invidious.service"];
      beforeServices = ["invidious.service"];
      afterServices = ["postgresql.service"];
      inherit config;
      inherit (pkgs) lib;
    };
in
  lib.mkMerge [
    create_database
    {
      sops.secrets."invidious/db_password" = {}; # secret_config;
      sops.secrets."invidious/settings.json" = {}; # secret_config;
      services.invidious = {
        enable = true;
        domain = "invidious.eyen.ca";
        port = 54105;
        package = pkgs.unstable.invidious;
        #database.passwordFile = config.sops.secrets."invidious/db_password".path;
        database.createLocally = false;
        #extraSettingsFile = config.sops.secrets."invidious/settings.json".path; #"$CREDENTIALS_DIRECTORY/settings.json";
        settings = {
          db = {user = "invidious";};
        };
      };
      systemd.services.invidious = {
        serviceConfig.LoadCredential = ["settings.json:${config.sops.secrets."invidious/settings.json".path}"];
      };
      services.nginx.virtualHosts.${config.services.invidious.settings.domain} = {
        forceSSL = true;
        useACMEHost = "eyen.ca";
        locations."/" = {
          proxyPass = "http://localhost:${builtins.toString config.services.invidious.port}";
        };
      };
      #users.users.invidious = {
      #  isSystemUser = true;
      #  group = "invidious";
      #};
      #users.groups.invidious = {
      #};
    }
  ]
