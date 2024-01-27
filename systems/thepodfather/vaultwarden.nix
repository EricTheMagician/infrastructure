{
  pkgs,
  config,
  ...
}: let
  create_database = import ../../functions/create_postgresql_db.nix {
    name = "vaultwarden";
    user_name = "vaultwarden";
    passwordFile = config.sops.secrets."vaultwarden/db_password".path;
    wantedBy = ["vaultwarden.service"];
    inherit config;
    inherit (pkgs) lib;
  };
  inherit (pkgs.lib) mkMerge;
in {
  imports = [../../modules/nginx.nix];

  config = mkMerge [
    {
      sops.secrets."vaultwarden/db_password" = {};
      sops.secrets."vaultwarden/env" = {
        format = "dotenv";
        sopsFile = ../../secrets/thepodfather/vaultwarden.env;
        restartUnits = ["vaultwarden.service"];
      };
      services.vaultwarden = {
        enable = true;
        package = pkgs.vaultwarden-postgresql;
        dbBackend = "postgresql";
        webVaultPackage = pkgs.vaultwarden-postgresql.webvault;
        environmentFile = config.sops.secrets."vaultwarden/env".path;
      };
      services.nginx.virtualHosts."vw.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:10224";
        };
      };
      #my.backups.paths = [config.services.vaultwarden.backupDir];
    }
    create_database
  ];
}
