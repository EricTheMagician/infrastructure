{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.stirling-pdf;
  inherit (lib) mkOption mkEnableOption mkIf types;
in {
  options.my.stirling-pdf = {
    enable = mkEnableOption "stirling-pdf";
    host = mkOption {
      type = types.str;
      default = "localhost";
    };
    port = mkOption {
      type = types.port;
      default = 6350;
    };
    package = mkOption {
      type = types.package;
      default = pkgs.unstable.stirling-pdf;
    };
    domain = mkOption {
      type = types.str;
      default = "pdfs.eyen.ca";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };

  config = mkIf cfg.enable {
    systemd.services.stirling-pdf = {
      environment = {
        SERVER_PORT = "${builtins.toString cfg.port}";
        SERVER_ADDRESS = cfg.host;
      };
      script = ''
        ${cfg.package}/bin/Stirling-PDF  #--host ${cfg.host} --port ${builtins.toString cfg.port}
      '';
      wantedBy = ["multi-user.target"];
      after = ["networking.target"];
      serviceConfig = {
        WorkingDirectory = "/var/lib/stirling-pdf";
        StateDirectory = "stirling-pdf";
        LogsDirectory = "stirling-pdf";
        DynamicUser = true;
      };
    };
    my.nginx.enable = true;
    services.nginx.virtualHosts.${cfg.domain} = {
      useACMEHost = cfg.acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString cfg.port}";
      };
    };
  };
}
