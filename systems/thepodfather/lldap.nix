{
  pkgs,
  config,
  ...
}: let
  domain = "lldap.eyen.ca";
  secret_owner = {
    owner = config.users.users.lldap.name;
    group = config.users.groups.lldap.name;
  };
  #ldaps_cert = config.security.acme.certs.${domain};
  ldaps_cert = config.security.acme.certs."eyen.ca";
in {
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
    package = pkgs.unstable.lldap;
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

  users.users.lldap.extraGroups = ["acme"];

  services.nginx.virtualHosts."${domain}" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString config.services.lldap.settings.http_port}";
    };
  };
  # setup the backup
  my.backup_paths = ["/var/lib/lldap/" "/var/lib/private/lldap"];
}
