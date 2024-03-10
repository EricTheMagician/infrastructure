{
  pkgs,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption mkEnableOption types mkIf;
  cfg = config.my.lldap;
  inherit (cfg) domain acme_host;
  secret_owner = {
    owner = config.users.users.lldap.name;
    group = config.users.groups.lldap.name;
  };
  #ldaps_cert = config.security.acme.certs.${domain};
  ldaps_cert = config.security.acme.certs.${acme_host};
in {
  options.my.lldap = {
    enable = mkEnableOption "lldap";
    domain = mkOption {
      type = types.str;
      default = "lldap.eyen.ca";
    };
    acme_host = mkOption {
      default = "eyen.ca";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    my.nginx.enable = true;
    # setup the users
    users.users.lldap = {
      name = "lldap";
      group = "lldap";
      isSystemUser = true;
    };

    users.groups.lldap = {};
    # setup the secrets
    sops.secrets = {
      "lldap/jwt_secret" = secret_owner;
      "lldap/ldap_user_pass" = secret_owner;
    };

    #setup the service
    services.lldap = {
      enable = true;
      package = pkgs.lldap;
      settings = {
        http_host = "localhost";
        http_url = "https://${domain}";
        ldap_base_dn = "dc=eyen,dc=ca";
        verbose = false;
      };
      environment = {
        LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."lldap/ldap_user_pass".path;
        LLDAP_JWT_SECRET_FILE = config.sops.secrets."lldap/jwt_secret".path;
        LLDAP_LDAPS_OPTIONS__ENABLED = "true";
        LLDAP_LDAPS_OPTIONS__CERT_FILE = "${ldaps_cert.directory}/cert.pem";
        LLDAP_LDAPS_OPTIONS__KEY_FILE = "${ldaps_cert.directory}/key.pem";
      };
    };
    networking.firewall.allowedTCPPorts = [
      config.services.lldap.settings.ldap_port
      6360 # ldaps port
    ];

    # allow the user to access the ssl certs
    users.users.lldap.extraGroups = ["acme"];

    services.nginx.virtualHosts."${domain}" = {
      useACMEHost = "eyen.ca";
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString config.services.lldap.settings.http_port}";
      };
    };
    # setup the backup
    my.backups.services.lldap = {
      paths = ["/var/lib/lldap/" "/var/lib/private/lldap"];
    };
  };
}
