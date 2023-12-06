let
  port = 27355;
  path = "/var/lib/plikd";
in {
  imports = [
    ../../modules/nginx.nix
  ];
  services.plikd = {
    enable = true;
    settings = {
      ListenPort = port;
      DownloadDomain = "https://dl.eyen.ca";
      SessionTimeout = "30d";
      SourceIpHeader = "X-Forwarded-For";
      MaxFileSizeStr = "30G";
      EnhancedWebSecurity = true;
      FeatureAuthentication = "forced";
      DataBackend = "file";
      DataBackendConfig = {Directory = "${path}/files";};
      MetadataBackendConfig = {
        Driver = "sqlite3";
        ConnectionString = "${path}/plik.db";
        Debug = false; # Log SQL requests
      };
    };
  };

  services.nginx.clientMaxBodySize = "${builtins.toString (30 * 1024)}G";
  services.nginx.virtualHosts."dl.eyen.ca" = {
    enableACME = true;
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString port}/";
    };
  };
}
