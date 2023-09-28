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
    LLDAP_JWT_SECRET = secret_owner;
    LLDAP_LDAP_USER_PASS = secret_owner;
  };

  #setup the service
  services.lldap = {
    enable = true;
    package = pkgs.unstable.lldap;
    settings = {
      http_host = "localhost";
      http_url = "https://${domain}";
      ldap_base_dn = "dc=eyen,dc=ca";
      #ldaps_enabled = true;
      #ldaps_port = 6360;
      #ldaps_cert_file = "${ldaps_cert.directory}/cert.pem";
      #ldaps_key_file = "${ldaps_cert.directory}/key.pem";
    };
    environment = {
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets.LLDAP_LDAP_USER_PASS.path;
      LLDAP_JWT_SECRET_FILE = config.sops.secrets.LLDAP_JWT_SECRET.path;
    };
  };
  networking.firewall.allowedTCPPorts = [
    config.services.lldap.settings.ldap_port
    #config.services.lldap.settings.ldaps_port
  ];

  #security.acme.certs.${domain} = {
  #  inherit domain;
  #  reloadServices = ["nginx" "lldap"];
  #};

  services.nginx.virtualHosts."${domain}" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${builtins.toString config.services.lldap.settings.http_port}";
    };
  };
  # setup the backup
  system_borg_backup_paths = ["/var/lib/lldap/"];
}
