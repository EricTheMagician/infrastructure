{
  inputs,
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption types mkOption;
  cfg = config.my.docker.tools.actual-budget;
  actual-address = "${cfg.host}:${builtins.toString cfg.port}";
in {
  imports = [
    inputs.arion.nixosModules.arion
  ];

  options.my.docker.tools.actual-budget = {
    enable = mkEnableOption "actual-budget";
    port = mkOption {
      type = types.port;
      description = "Port for actual-budget";
      default = 22600;
    };
    host = mkOption {
      type = types.str;
      description = "Host for actual-budget";
      default = "127.0.0.1";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };

  config = mkIf cfg.enable {
    my.nginx.enable = true;
    virtualisation.arion.projects.utils.settings.services = {
      actual-server.service = {
        container_name = "actual-server";
        image = "docker.io/actualbudget/actual-server:latest";
        restart = "unless-stopped";
        ports = ["${actual-address}:5006"];
        volumes = [
          "/var/lib/actual-server/:/data"
        ];
      };
    };
    services.nginx.virtualHosts."budget.eyen.ca" = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
      locations."/".proxyPass = "http://${actual-address}/";
    };
    my.backups.services.actual-budget = {
      paths = ["/var/lib/actual-server"];
      startAt = "weekly";
      keep = {
        daily = null;
        weekly = 4;
        months = 24;
      };
    };
  };
}
