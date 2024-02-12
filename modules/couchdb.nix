{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption mkOption types;
  cfg = config.my.couchdb;
in {
  options.my.couchdb = {
    enable = mkEnableOption "couchdb";
    domain = mkOption {
      type = types.str;
      default = "couch.eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    my.nginx.enable = true;
    my.acme.enable = true;

    services.couchdb = {
      enable = true;
      extraConfig = ''
        [couchdb]
        single_node=true
      '';
    };

    services.nginx.virtualHosts.${cfg.domain} = {
      forceSSL = true;
      enableACME = true;
      locations."/" = {proxyPass = "http://localhost:${builtins.toString config.services.couchdb.port}";};
    };

    my.backups.services.couchdb = {
      paths = [config.services.couchdb.viewIndexDir config.services.couchdb.databaseDir];
      keep = {
        daily = 7;
        weekly = 8;
        monthly = 6;
      };
    };
  };
}
