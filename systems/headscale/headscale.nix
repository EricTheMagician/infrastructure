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
  ...
}: let
  domain = "hs.eyen.ca";
  inherit ((import ../../common/dns)) tailscale_dns_entries;
  build_borg_backup_job = import ../../functions/borg-job.nix;
in {
  imports = [
    ../../modules/knownHosts.nix
    ../../modules/nginx.nix
  ];
  environment.systemPackages = [
    pkgs.unstable.headscale # needed for the headscale cli utility
  ];

  networking.firewall = {
    allowedTCPPorts = [80 443]; # open the http/https and grpc port for headscale
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
        #nameservers = ["100.64.0.1" "100.64.0.14"];
        #nameservers = ["100.64.0.9" "100.64.0.14"];
        #nameservers = ["https://dns.nextdns.io/f2314b"]; # nextdns
        #nameservers = ["45.90.28.207" "45.90.30.207" "2a07:a8c0::ad:3362" "2a07:a8c1::ad:3362"];
        nameservers = ["https://dns.nextdns.io/ad3362" "2a07:a8c0::ad:3362" "2a07:a8c1::ad:3362"];
        magic_dns = false;
        override_local_dns = true;
        domains = ["eyen.ca"];
        #extra_records = tailscale_dns_entries;
      };
    };
  };

  systemd.timers.borgbackup-job-headscale-config.timerConfig.RandomizedDelaySec = 3600;
  services.borgbackup.jobs.headscale-config =
    build_borg_backup_job {
      inherit config;
      paths = [(config.services.headscale.settings.db_path + "/..")];
      name = "headscale-config";
      patterns = [
        "+ ${config.services.headscale.settings.db_path}"
        ("- " + (config.services.headscale.settings.db_path + "/.."))
      ];
      keep = {
        daily = 7;
        weekly = 4;
        monthly = 3;
      };
    }
    // {
      postHook = ''
        PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
                  ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/headscale/$exitStatus" --silent
      '';
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
}
