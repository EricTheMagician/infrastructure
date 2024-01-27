{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkIf mkEnableOption types;
in {
  imports = [
    ./borg.nix
    ./sops.nix
  ];
  options.my.acme = {
    enable = mkEnableOption "ACME";
  };
  config = mkIf config.my.acme.enable {
    # backup the generated certs
    my.backups.paths = ["/var/lib/acme"];

    # ensure that default acme group is created and nginx is part of me
    # the group has permission to read the cloudflare private key
    users.groups.${config.security.acme.defaults.group} = {};
    security.acme = {
      acceptTerms = true;
      defaults.reloadServices = ["nginx"];
      certs."eyen.ca" = {
        domain = "*.eyen.ca";
      };

      defaults = {
        dnsResolver = "1.1.1.1:53";
        webroot = null;
        email = "e@eyen.ca";
        dnsProvider = "cloudflare";
        credentialsFile = config.sops.secrets."cloudflare/api_key".path;
      };
    };
    sops = {
      # This is the actual specification of the secrets.
      secrets."cloudflare/api_key" = {
        mode = "0440";
        sopsFile = ../secrets/cloudflare-api.env;
        format = "dotenv";
        inherit (config.security.acme.defaults) group;
      };
    };
  };
}
