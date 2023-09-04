{config, ...}: {
  imports = [
    ./sops.nix
  ];
  # ensure that default acme group is created and nginx is part of me
  # the group has permission to read the cloudflare private key
  users.groups.${config.security.acme.defaults.group} = {};

  security.acme = {
    acceptTerms = true;
    defaults = {
      email = "e@eyen.ca";
      dnsProvider = "cloudflare";
      credentialsFile = "/run/secrets/cloudflare_api_dns";
    };
  };
  sops = {
    # This is the actual specification of the secrets.
    secrets."cloudflare_api_dns" = {
      mode = "0440";
      sopsFile = ../secrets/cloudflare-api.yaml;
      group = config.security.acme.defaults.group;
    };
  };
}
