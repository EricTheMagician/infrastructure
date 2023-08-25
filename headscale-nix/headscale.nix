####################
#
# NOTE:
# You need to manually create the folder "/run/headscale"
# or the service will fail to start
#
#####################

{ config, pkgs, unstable, ... }:
let
  unstable = import <nixos-unstable> { config = config.nixpkgs.config; };
  domain = "hs.eyen.ca";
  docker_host = "100.64.0.2";

  # This is a function that takes in 2 parameters, name and ip
  # to generate the dns entries for headscale
  unraid_apps = import ../common/dns/unraid_apps.nix;
  domain_name = "eyen.ca";
  unraid_ts_ip = "100.64.0.2";
  unraid_ts_dns = map (app: { name = "${app}.${domain_name}"; type = "A"; value = unraid_ts_ip; }) unraid_apps;
  office_dns = import ../common/dns/office_apps.nix;
  office_ts_dns = map (app: { name = "${app.domain}"; type = "A"; value = "${app.answer}"; }) office_dns;


in
{
  environment.systemPackages = [
    unstable.headscale # needed for the headscale cli utility
  ];


  networking.firewall = {
    allowedTCPPorts = [ 80 443 50443 ]; # open the http/https and grpc port for headscale
    enable = true;
  };

  services.headscale = {
    enable = true;
    port = 443;
    address = "0.0.0.0";
    package = unstable.headscale;
    settings = {
      server_url = "https://${domain}";
      # tls_letsencrypt_listen = ":http = port 80";
      tls_letsencrypt_hostname = "${domain}";
      logtail.enabled = false;
      #      ip_prefixes = [ "fd7a:115c:a1e0::/48" "100.64.0.0/10" ];
      ip_prefixes = [ "100.64.0.0/10" ];
      private_key_path = "/var/lib/headscale/private.key";
      noise.private_key_path = "/var/lib/headscale/noise_private.key";
      dns_config = {
        nameservers = [ "10.64.0.9" "1.1.1.1" ];
        baseDomain = "ts.lan";
        override_local_dns = true;
        extra_records = [
          {
            name = "headscale.${domain_name}";
            value = "100.64.0.1";
            type = "A";
          }

        ] ++ unraid_ts_dns ++ office_ts_dns;
        # Search domains to inject.
        domains = [
          "eyen.ca"
        ];
      };
    };
  };
}
