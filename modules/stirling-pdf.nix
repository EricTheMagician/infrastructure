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
        HOME = "/var/lib/stirling-pdf";
      };
      path = [pkgs.unoconv pkgs.python3Packages.weasyprint pkgs.ocrmypdf];
      script = ''
        ${cfg.package}/bin/Stirling-PDF
      '';
      wantedBy = ["multi-user.target"];
      after = ["networking.target"];
      serviceConfig = {
        WorkingDirectory = "/var/lib/stirling-pdf";
        StateDirectory = "stirling-pdf";
        LogsDirectory = "stirling-pdf";
        # this needs to be a normal user to be able to execute subprocesses with libreoffice
        User = "stirling-pdf";
        Group = "stirling-pdf";
      };
    };
    users.users.stirling-pdf = {
      group = "stirling-pdf";
      isSystemUser = true;
    };
    users.groups.stirling-pdf = {
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
