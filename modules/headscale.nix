####################
#
# NOTE:
# You need to manually create the folder "/run/headscale"
# or the service will fail to start
#
#####################
{
  inputs,
  config,
  pkgs,
  ...
}: let
  domain = "hs.eyen.ca";
  unstable = inputs.nixpkgs-unstable.legacyPackages.x86_64-linux;
  tailscale_dns_entries = (import ../common/dns).tailscale_dns_entries;
in {
  environment.systemPackages = [
    unstable.headscale # needed for the headscale cli utility
  ];

  networking.firewall = {
    allowedTCPPorts = [80 443 50443]; # open the http/https and grpc port for headscale
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
      ip_prefixes = ["100.64.0.0/10"];
      private_key_path = "/var/lib/headscale/private.key";
      noise.private_key_path = "/var/lib/headscale/noise_private.key";
      disable_check_updates = true; # use nix to manage that
      derp = {
        server = {
          enabled = false;
        };
      };
      dns_config = {
        nameservers = ["100.64.0.9" "100.64.0.16"];
        baseDomain = "ts.lan";
        override_local_dns = true;
        extra_records = tailscale_dns_entries;

        # Search domains to inject.
        domains = [
          "eyen.ca"
        ];
      };
    };
  };
}
