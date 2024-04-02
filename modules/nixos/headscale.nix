####################
#
# NOTE:
# You need to manually create the folder "/run/headscale"
# or the service will fail to start
#
#####################
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.headscale;
  inherit (lib) mkIf mkOption mkEnableOption types;
  inherit (cfg) domain;
in {
  options.my.headscale = {
    enable = mkEnableOption "Enable Headscale service";
    domain = mkOption {
      type = types.str;
      default = "hs.eyen.ca";
      description = "The domain of the headscale instance";
    };
    acme_host = mkOption {
      type = types.str;
      default = "eyen.ca";
    };
  };
  config = mkIf cfg.enable {
    my.nginx.enable = true;
    my.acme.enable = true;

    environment.systemPackages = [
      pkgs.unstable.headscale # needed for the headscale cli utility
    ];

    networking.firewall = {
      allowedUDPPorts = [3478]; # derp server
      enable = true;
    };

    services.headscale = {
      enable = true;
      port = 8080;
      address = "0.0.0.0";
      package = pkgs.unstable.headscale;
      settings = {
        server_url = "https://${domain}";
        # tls_letsencrypt_listen = ":http = port 80";
        #tls_letsencrypt_hostname = "${domain}";
        tls_cert_path = config.security.acme.certs.${domain}.directory + "/cert.pem";
        tls_key_path = config.security.acme.certs.${domain}.directory + "/key.pem";
        logtail.enabled = false;
        ip_prefixes = ["100.64.0.0/10" "fd7a:115c:a1e0::/48"];
        private_key_path = "/var/lib/headscale/private.key";
        noise.private_key_path = "/var/lib/headscale/noise_private.key";
        disable_check_updates = true; # use nix to manage that
        derp = {
          server = {
            enabled = true;
            stun_listen_addr = "0.0.0.0:3478";
            region_id = 900;

            # Region code and name are displayed in the Tailscale UI to identify a DERP region
            region_code = "headscale";
            region_name = "Headscale Embedded DERP";
          };
          paths = [
          ];
        };
        dns_config = {
          nameservers = ["45.90.28.0#ad3362.dns.nextdns.io" "45.90.30.0#ad3362.dns.nextdns.io" "https://dns.nextdns.io/ad3362" "2a07:a8c0::ad:3362" "2a07:a8c1::ad:3362"];
          # nameservers = ["100.64.0.14" "100.64.0.18"];
          magic_dns = false;
          override_local_dns = true;
          domains = ["eyen.ca"];
          extra_records = (import ../../common/dns).tailscale_dns_entries;
        };
      };
    };
    # make the headscale stop time shorter so that restarting it is a lot faster
    systemd.services.headscale.serviceConfig.TimeoutStopSec = "30s";

    my.backups.services.headscale = {
      startAt = "weekly";
      keep = {
        weekly = 4;
        monthly = 3;
      };
      paths = [(config.services.headscale.settings.db_path + "/..")];
    };

    security.acme.certs.${domain} = {
      inherit domain;
      group = "nginx";
    };
    users.users.headscale = {
      extraGroups = ["nginx"];
    };
    services.nginx.virtualHosts.${domain} = {
      useACMEHost = domain;
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://${config.services.headscale.address}:${toString config.services.headscale.port}";
        proxyWebsockets = true;
      };
    };
  };
}
