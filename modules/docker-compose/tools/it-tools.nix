{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption types mkOption;
  cfg = config.my.docker.tools.it-tools;
  it-tools-address = "${cfg.host}:${builtins.toString cfg.port}";
in {
  imports = [
    inputs.arion.nixosModules.arion
  ];

  options.my.docker.tools.it-tools = {
    enable = mkEnableOption "it-tools";
    port = mkOption {
      type = types.port;
      description = "Port for it-tools";
      default = 43760;
    };
    host = mkOption {
      type = types.str;
      description = "Host for it-tools";
      default = "127.0.0.1";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    virtualisation.arion.projects.utils.settings.services = {
      it-tools.service = {
        container_name = "it-tools";
        image = "ghcr.io/corentinth/it-tools:latest";
        restart = "unless-stopped";
        ports = ["${it-tools-address}:80"];
      };
    };

    services.nginx.virtualHosts."it-tools.eyen.ca" = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
      locations."/".proxyPass = "http://${it-tools-address}/";
    };
  };
}
