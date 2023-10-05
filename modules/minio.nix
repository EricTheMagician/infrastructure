{
  pkgs,
  unstable,
  config,
  ...
}: let
  console_address = "minio-web.eyen.ca";
  api_address = "minio-api.eyen.ca";
in {
  #disabledModules = ["nixos/modules/services/web-servers/minio.nix"];
  #imports = [(inputs.nixpkgs-unstable + "nixos/modules/services/web-servers/minio.nix")];
  imports = [../modules/nginx.nix];
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
      package = unstable.minio;
      rootCredentialsFile = config.sops.secrets.minio_credentials.path;
      dataDir = ["/data/minio"];
      region = "mini-nix";
    };

    nginx.virtualHosts = {
      ${console_address} = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:9001";
          proxyWebsockets = true;
        };
      };

      ${api_address} = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:9000";
        };
      };
    };
  };
  systemd.services.minio.environment = {
    MINIO_BROWSER_REDIRECT_URL = "https://minio-web.eyen.ca";
    MINIO_SERVER_URL = "https://minio-api.eyen.ca";
  };
}
