{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkIf mkOption types mkEnableOption;
  cfg = config.my.minio;
in {
  #disabledModules = ["nixos/modules/services/web-servers/minio.nix"];
  #imports = [(inputs.nixpkgs-unstable + "nixos/modules/services/web-servers/minio.nix")];
  imports = [./nginx.nix ./acme.nix ./sops.nix];
  options.my.minio = {
    enable = mkEnableOption "minio";
    console_address = mkOption {
      type = types.str;
      description = "browser address";
    };
    api_address = mkOption {
      type = types.str;
      description = "api address";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
      description = "which cert to use";
    };
    data_dirs = mkOption {
      type = types.listOf types.str;
      description = "data paths to store minio data";
    };
    region = mkOption {
      type = types.str;
      default = "mini-nix";
    };
  };

  config = mkIf cfg.enable {
    sops = {
      # This is the actual specification of the secrets.
      secrets."minio_credentials" = {
        mode = "0440";
        sopsFile = ../secrets/mini-nix/minio.yaml;
        owner = "minio";
        group = "minio";
      };
    };

    services = {
      minio = {
        enable = true;
        package = pkgs.unstable.minio;
        rootCredentialsFile = config.sops.secrets.minio_credentials.path;
        dataDir = ["/data/minio"];
        inherit (cfg) region;
      };

      nginx.virtualHosts = {
        ${cfg.console_address} = {
          useACMEHost = "eyen.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:9001";
            proxyWebsockets = true;
          };
        };

        ${cfg.api_address} = {
          useACMEHost = "eyen.ca";
          forceSSL = true;
          locations."/" = {
            proxyPass = "http://localhost:9000";
          };
        };
      };
    };
    systemd.services.minio.environment = {
      MINIO_BROWSER_REDIRECT_URL = "https://${cfg.console_address}";
      MINIO_SERVER_URL = "https://${cfg.api_address}";
    };
  };
}
