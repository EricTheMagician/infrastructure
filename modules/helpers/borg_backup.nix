{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mapAttrs mapAttrs' mkIf mkMerge nameValuePair;
  cfg = lib.filterAttrsRecursive (k: v: v != null) config.my.backups.services;
  service_backup_enabled = builtins.length (builtins.attrNames cfg) > 0;
  create_borg_backup_job = name: attrs: let
    healthcheck-namme = "${config.networking.hostName}-${name}";
  in {
    services.borgbackup.jobs.${name} = {
      inherit (attrs) paths startAt;
      # group = "borg-backup";
      doInit = true;
      repo = "ssh://borg@borg-backup-server/./${config.networking.hostName}";
      compression = "auto,zstd";
      archiveBaseName = "${config.networking.hostName}-${name}";
      encryption = {
        mode = "repokey-blake2";
        passCommand = "cat ${config.sops.secrets."borg/password".path}";
      };
      environment = {BORG_RSH = "ssh -i ${config.sops.secrets."borg/private_key".path}";};
      prune.keep = attrs.keep;
      persistentTimer = true;
      environment = {
        #BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
      };
      postHook = ''
        PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
        ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${healthcheck-namme}/$exitStatus" --silent
      '';
    };
    # add the creation and resuming/pausing of healthchecks
    #systemd.services."healthchecks-job-${name}" = {
    #  preStart = let
    #    json_data = {
    #      name = healthcheck-namme;
    #      slug = healthcheck-namme;
    #      desc = "Backup ${name} on ${config.networking.hostName}";
    #      grace =
    #        if attrs.startAt == "weekly"
    #        then builtins.toString (3600 * 24 * 7 + 3600 + 6 * 3600)
    #        else builtins.toString (3600 * 6);
    #      channels = "*";
    #      unique = ["name" "slug"];
    #    };
    #  in ''
    #    API_KEY=`cat ${config.sops.secrets.healthchecks_api_key.path}`
    #    # upsert a new endpoints
    #    ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/api/v3/checks/" --silent \
    #      -X POST \
    #      -H "Content-Type: application/json" \
    #      -H "X-Api-Key: $API_KEY" \
    #      -d "${builtins.toJSON json_data}"
    #     # resume the check in case it was paused previously
    #     RESUME_URL=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" https://healthchecks.eyen.ca/api/v3/checks/ \
    #        | ${pkgs.jq}/bin/jq -r '.checks[] | select(.name=="${healthcheck-namme}").resume_url')
    #    ${pkgs.curl}/bin/curl "$RESUME_URL" --silent -X POST -H "X-Api-Key: $API_KEY"
    #  '';
    #  preStop = ''
    #    API_KEY=`cat ${config.sops.secrets.healthchecks_api_key.path}`
    #    PAUSE_URL=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" https://healthchecks.eyen.ca/api/v3/checks/ \
    #        | ${pkgs.jq}/bin/jq -r '.checks[] | select(.name=="${healthcheck-namme}").pause_url')
    #    ${pkgs.curl}/bin/curl "$PAUSE_URL" --silent -X POST -H "X-Api-Key: $API_KEY"
    #  '';
    #};
    #systemd.timers = {
    #  "borgbackup-job-${name}".timerConfig.RandomizedDelaySec = 3600 * 3;
    #};
  };
  mkJob = name: attrs: (let
    healthcheck-namme = "${config.networking.hostName}-${name}";
  in {
    inherit (attrs) paths startAt;
    # group = "borg-backup";
    doInit = true;
    repo = "ssh://borg@borg-backup-server/./${config.networking.hostName}";
    compression = "auto,zstd";
    archiveBaseName = "${config.networking.hostName}-${name}";
    encryption = {
      mode = "repokey-blake2";
      passCommand = "cat ${config.sops.secrets."borg/password".path}";
    };
    environment = {BORG_RSH = "ssh -i ${config.sops.secrets."borg/private_key".path}";};
    prune.keep = attrs.keep;
    persistentTimer = true;
    environment = {
      #BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
    };
    postHook = ''
      PING_KEY=`cat ${config.sops.secrets.ping_key.path}`
      ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${healthcheck-namme}/$exitStatus" --silent
    '';
  });
  mkHealthCheck = name: attrs: (
    let
      healthcheck-namme = "${config.networking.hostName}-${name}";
    in {
      name = "healthchecks-job-${name}";
      value = {
        wantedBy = ["multi-user.target"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        preStart = let
          json_data = {
            name = healthcheck-namme;
            slug = healthcheck-namme;
            desc = "Backup ${name} on ${config.networking.hostName}";
            grace = 3600 * 6; # 6 hours
            tags = [config.networking.hostName name];
            timeout =
              if attrs.startAt == "weekly"
              then (3600 * 24 * 7)
              else (3600 * 24);
            channels = "*";
            unique = ["name" "slug"];
          };
        in ''
          API_KEY=`cat ${config.sops.secrets.healthchecks_api_key.path}`
          # upsert a new endpoints
          echo "Upsering healthcheck ${healthcheck-namme}"
          ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/api/v3/checks/" --silent \
            -X POST \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $API_KEY" \
            -d '${builtins.toJSON json_data}'
           # resume the check in case it was paused previously
           echo "Getting resume url for healthcheck ${healthcheck-namme}"
           RESUME_URL=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" https://healthchecks.eyen.ca/api/v3/checks/ | ${pkgs.jq}/bin/jq -r '.checks[] | select(.name=="${healthcheck-namme}").resume_url')
           echo "Resuming healthcheck ${healthcheck-namme} at $RESUME_URL"
          ${pkgs.curl}/bin/curl "$RESUME_URL" --silent -X POST -H "X-Api-Key: $API_KEY"
        '';
        preStop = ''
          API_KEY=`cat ${config.sops.secrets.healthchecks_api_key.path}`
          PAUSE_URL=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" https://healthchecks.eyen.ca/api/v3/checks/ \
              | ${pkgs.jq}/bin/jq -r '.checks[] | select(.name=="${healthcheck-namme}").pause_url')
          ${pkgs.curl}/bin/curl "$PAUSE_URL" --silent -X POST -H "X-Api-Key: $API_KEY"
        '';
      };
    }
  );
  mkTimerRandomization = name: value: {
    name = "borgbackup-job-${name}";
    value = {timerConfig.RandomizedDelaySec = 3600 * 3;};
  };
in {
  services.borgbackup.jobs = mapAttrs mkJob cfg;
  systemd.services = mapAttrs' mkHealthCheck cfg;
  systemd.timers = mapAttrs' mkTimerRandomization cfg;
}
#in mkMerge (mapAttrs create_borg_backup_job cfg.services)

