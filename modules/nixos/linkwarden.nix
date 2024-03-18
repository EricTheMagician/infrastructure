{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  cfg = config.my.linkwarden;
  inherit (lib) mkIf mkOption mkEnableOption types;
  mypkgs = import inputs.mynixpkgs {
    inherit (pkgs) system;
    config.allowUnfree = true; # final.config.allowUnfree;
  };
in {
  options.my.linkwarden = {
    enable = mkEnableOption "linkwarden";
    port = mkOption {
      default = 12522;
      type = types.port;
    };
    acme_host = mkOption {
      default = "eyen.ca";
      type = types.str;
    };
  };
  imports = [
    (inputs.mynixpkgs + "/nixos/modules/services/web-apps/linkwarden.nix")
  ];
  config = mkIf cfg.enable {
    sops.secrets."linkwarden/env" = {
      sopsFile = ../../secrets/linkwarden.env;
      restartUnits = ["linkwarden.service"];
      format = "dotenv";
    };
    services.linkwarden = {
      inherit (cfg) port;
      enable = true;
      package = mypkgs.linkwarden;
      settingsFile = config.sops.secrets."linkwarden/env".path;
      settings = {
        NEXTAUTH_URL = "https://linkwarden.eyen.ca:443/api/v1/auth";
        # NEXTAUTH_URL = "https://linkwarden.eyen.ca:443";
        NEXT_PUBLIC_DISABLE_REGISTRATION = "false";
        VIRTUAL_PORT = builtins.toString cfg.port;
        VIRTUAL_HOST = "linkwarden.eyen.ca";
      };
    };
    my.nginx.enable = true;
    my.postgresql.enable = true;
    my.backups.services.linkwarden = {
      paths = ["/var/lib/linkwarden"];
      postgres_databases = ["linkwarden"];
    };
    services.nginx.virtualHosts."linkwarden.eyen.ca" = {
      forceSSL = true;
      useACMEHost = cfg.acme_host;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString cfg.port}";
        # proxyWebsockets = true;
      };
    };
  };
}
