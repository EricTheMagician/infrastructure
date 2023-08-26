{ config, pkgs, sops, ... }:
let
in
{
  imports = [
    ./sops.nix
  ];
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
  # ensure that default acme group is created and nginx is part of me
  # the group has permission to read the cloudflare private key
  users.groups.${config.security.acme.defaults.group} = { };
  users.users.nginx.extraGroups = [ config.security.acme.defaults.group ];
  networking.firewall = {
    # ports needed for dns
    allowedTCPPorts = [ 80 443 ];
  };

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



