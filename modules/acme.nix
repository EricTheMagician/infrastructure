{
  config,
  pkgs,
  ...
}: let
  build_borg_backup_job = import ../functions/borg-job.nix;
in {
  imports = [
    ./borg.nix
    ./sops.nix
  ];
  # ensure that default acme group is created and nginx is part of me
  # the group has permission to read the cloudflare private key

  systemd.timers.borgbackup-job-acme.timerConfig.RandomizedDelaySec = 3600 * 3;
  services.borgbackup.jobs.acme =
    build_borg_backup_job {
      inherit config;
      paths = ["${config.sops.secrets.BORG_BACKUP_PASSWORD.path}"];
      name = "acme";
      startAt = "daily";
      keep = {
        daily = 3;
        weekly = 4;
      };
    }
    // {
      postHook = ''
        PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
        ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${config.networking.hostName}-acme/$exitStatus" --silent
      '';
    };

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
      inherit (config.security.acme.defaults) group;
    };
  };
}
