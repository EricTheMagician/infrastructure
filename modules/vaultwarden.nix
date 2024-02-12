{
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.lib) mkIf mkEnableOption types mkOption;
  cfg = config.my.vaultwarden;
in {
  options.my.vaultwarden = {
    enable = mkEnableOption "vaultwarden";
    domain = mkOption {
      type = types.str;
      description = "Domain for vaultwarden";
      default = "vw.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    my.postgresql.enable = true;
    my.nginx.enable = true;
    sops.secrets."vaultwarden/env" = {
      format = "dotenv";
      sopsFile = ../secrets/vaultwarden.env;
      restartUnits = ["vaultwarden.service"];
    };
    services.vaultwarden = {
      enable = true;
      package = pkgs.vaultwarden-postgresql;
      dbBackend = "postgresql";
      webVaultPackage = pkgs.vaultwarden-postgresql.webvault;
      environmentFile = config.sops.secrets."vaultwarden/env".path;
    };
    services.nginx.virtualHosts."${cfg.domain}" = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:10224";
      };
    };
    my.backups.services.vaultwarden.postgres_databases = ["vaultwarden"];
    services.postgresqlBackup.databases = ["vaultwarden"];
    services.postgresql = {
      ensureDatabases = ["vaultwarden"];
      ensureUsers = [
        {
          name = "vaultwarden";
          ensureDBOwnership = true;
        }
      ];
    };
  };
}
