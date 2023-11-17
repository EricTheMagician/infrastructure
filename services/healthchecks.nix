{
  config,
  pkgs,
  ...
}: let
  build_borg_backup_job = import ../functions/borg-job.nix;
  domain = "healthchecks.eyen.ca";
  acme_host = "eyen.ca";
in {
  imports = [
    ../services/acme-default.nix
    ../modules/nginx.nix
    ../modules/knownHosts.nix
  ];
  # create a healthchecks secret key
  sops = {
    # This is the actual specification of the secrets.
    secrets."healthchecks" = {
      mode = "0400";
      sopsFile = ../secrets/healthchecks.yaml;
      inherit (config.services.healthchecks) group;
      owner = config.services.healthchecks.user;
      restartUnits = ["healthchecks.service"];
    };
  };

  # enable healthchecks services
  services = {
    healthchecks = {
      enable = true;
      package = pkgs.unstable.healthchecks.overrideAttrs (final: prev: let
        localSettings = pkgs.writeText "local_settings.py" ''
          import os
          STATIC_ROOT = os.getenv("STATIC_ROOT")

          with open("${config.sops.secrets.healthchecks.path}", "r") as file:
              for line in file.readlines():
                  try:
                      key, value = line.split("=")
                  except:
                      # just in case there are any isssues with parsing the file.
                      # might happen if the file contains an extra line at the
                      # end of the file.
                      continue
                  key = key.strip()
                  value = value.strip()
                  try:
                      value = int(value)
                  except:
                      pass
                  if value == "True":
                      value = True
                  elif value == "False":
                      value = False
                  globals()[key] = value
        '';
      in {
        installPhase = ''
          mkdir -p $out/opt/healthchecks
          cp -r . $out/opt/healthchecks
          chmod +x $out/opt/healthchecks/manage.py
          cp ${localSettings} $out/opt/healthchecks/hc/local_settings.py
        '';
      });
      settings = {
        REGISTRATION_OPEN = true;
        ALLOWED_HOSTS = [domain];
        SECRET_KEY_FILE = config.sops.secrets.healthchecks.path;
        ADMINS = "eric@ericyen.com";
        SITE_ROOT = "https://${domain}";
      };
    };

    # reverse proxy to healthchecks
    nginx.virtualHosts.${domain} = {
      useACMEHost = acme_host;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://localhost:${builtins.toString config.services.healthchecks.port}";
      };
    };

    # create a backup for healthchecks
    borgbackup.jobs.healthchecks =
      build_borg_backup_job {
        inherit config;
        paths = [config.services.healthchecks.dataDir];
        name = "healthchecks";
        keep = {
          daily = 7;
          weekly = 4;
        };
        patterns = [
          "- ${config.services.healthchecks.dataDir + "/static"}"
        ];
      }
      // {
        postHook = ''
          PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
          ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/healthchecks/$exitStatus" --silent
        '';
      };
  };
  systemd.timers.borgbackup-job-healthchecks.timerConfig.RandomizedDelaySec = 3600 * 3;
}
