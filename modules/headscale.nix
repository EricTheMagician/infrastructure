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
  build_borg_backup_job = import ../functions/borg-job.nix;
in {
  imports = [
    ../modules/knownHosts.nix
  ];
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
        #nameservers = ["100.64.0.1" "100.64.0.14"];
        #nameservers = ["100.64.0.9" "100.64.0.14"];
        nameservers = ["45.90.28.207" "45.90.30.207"]; # nextdns
        magic_dns = false;
        override_local_dns = true;
        domains = ["eyen.ca"];
        extra_records = tailscale_dns_entries;
      };
    };
  };

  # manage backups of the currrent headscale data
  sops = {
    secrets.BORG_BACKUP_PASSWORD = {
      mode = "0400";
      sopsFile = ../secrets/borg-backup.yaml;
    };
    secrets.BORG_PRIVATE_KEY = {
      mode = "0400";
      sopsFile = ../secrets/borg-backup.yaml;
    };
  };

  systemd.timers.borgbackup-job-headscale-config.timerConfig.RandomizedDelaySec = 3600;
  services.borgbackup.jobs.headscale-config =
    build_borg_backup_job {
      inherit config;
      paths = [(builtins.toPath (config.services.headscale.settings.db_path + "/.."))];
      name = "headscale-config";
      patterns = [
        "+ ${config.services.headscale.settings.db_path}"
        ("- " + (builtins.toPath (config.services.headscale.settings.db_path + "/..")))
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
}
