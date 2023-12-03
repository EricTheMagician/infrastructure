{config, ...}: let
  cfg = config.services.couchdb;
in {
  services.couchdb = {
    enable = true;
    extraConfig = ''
      [couchdb]
      single_node=true
    '';
  };

  services.nginx.virtualHosts."couch.eyen.ca" = {
    forceSSL = true;
    enableACME = true;
    locations."/" = {proxyPass = "http://localhost:${builtins.toString cfg.port}";};
  };
  my.backup_paths = [cfg.viewIndexDir cfg.databaseDir];
}
