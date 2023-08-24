{ config, pkgs, ... }:
let
in
{
  services.nginx = {
    enable = true;
    recommendedProxySettings = true;
    recommendedTlsSettings = true;
  };
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
}



