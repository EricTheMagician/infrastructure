{
  config,
  lib,
  ...
}: let
  cfg = config.my.plikd;
  inherit (lib) mkIf mkOption types mkEnableOption;
  datapath = "/var/lib/plikd";
in {
  options.my.plikd = {
    enable = mkEnableOption "Enable Plikd service";
    port = mkOption {
      type = types.port;
      default = 27355;
    };
    datapath = mkOption {
      type = types.str;
    };
    domain = mkOption {
      type = types.str;
      default = "dl.eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    my.nginx.enable = true;
    my.acme.enable = true;
    services.plikd = {
      enable = true;
      settings = {
        ListenPort = cfg.port;
        DownloadDomain = "https://${cfg.domain}";
        SessionTimeout = "30d";
        SourceIpHeader = "X-Forwarded-For";
        MaxFileSizeStr = "30G";
        EnhancedWebSecurity = true;
        FeatureAuthentication = "forced";
        DataBackend = "file";
        DataBackendConfig = {Directory = "${datapath}/files";};
        MetadataBackendConfig = {
          Driver = "sqlite3";
          ConnectionString = "${datapath}/plik.db";
          Debug = false; # Log SQL requests
        };
      };
    };

    my.backups.services.plikd = {
      paths = [datapath];
      keep = {
        daily = 7;
        weekly = null;
        monthly = null;
      };
    };

    services.nginx.clientMaxBodySize = "${builtins.toString (30 * 1024)}G";
    services.nginx.virtualHosts."dl.eyen.ca" = {
      enableACME = true;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString cfg.port}/";
      };
    };
  };
}
