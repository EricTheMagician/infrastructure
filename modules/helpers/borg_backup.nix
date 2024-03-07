{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mapAttrs mapAttrs' mapAttrsToList concatLists;
  cfg = lib.filterAttrsRecursive (k: v: v != null) config.my.backups.services;
  compressSuffixes = {
    "none" = "";
    "gzip" = ".gz";
    "zstd" = ".zstd";
  };
  compressSuffix = lib.getAttr config.services.postgresqlBackup.compression compressSuffixes;

  database_files = builtins.map (backup: "${config.services.postgresqlBackup.location}/${backup}.sql${compressSuffix}");

  mkJob = name: attrs: (let
    healthcheck-name = "${config.networking.hostName}-${name}";
  in {
    inherit (attrs) startAt;
    #inherit (attrs) startAt paths;
    paths = attrs.paths ++ (database_files attrs.postgres_databases);
    # group = "borg-backup";
    doInit = true;
    repo = "ssh://borg@borg-backup-server/./${healthcheck-name}";
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
      ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/ping/$PING_KEY/${healthcheck-name}/$exitStatus" --silent
    '';
  });
  mkHealthCheck = name: attrs: (
    let
      healthcheck-namme = "${config.networking.hostName}-${name}";
    in {
      name = "healthchecks-job-${name}";
      value = {
        wantedBy = ["multi-user.target"];
        after = lib.optionals config.my.healthchecks.enable ["healthchecks.service"];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = let
          json_data = {
            name = healthcheck-namme;
            slug = healthcheck-namme;
            desc = "Backup ${name} on ${config.networking.hostName}";
            grace = 3600 * 6; # 6 hours
            tags = "${config.networking.hostName} ${name}";
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
          echo "Upserting healthcheck ${healthcheck-namme}"
          ${pkgs.curl}/bin/curl "https://healthchecks.eyen.ca/api/v3/checks/" \
            -X POST \
            --silent \
            -H "Content-Type: application/json" \
            -H "X-Api-Key: $API_KEY" \
            -d '${builtins.toJSON json_data}'
          # resume the check in case it was paused previously
          # echo "Getting resume url for healthcheck ${healthcheck-namme}"
          # RESUME_URL=$(${pkgs.curl}/bin/curl -s -H "X-Api-Key: $API_KEY" https://healthchecks.eyen.ca/api/v3/checks/ | ${pkgs.jq}/bin/jq -r '.checks[] | select(.name=="${healthcheck-namme}").resume_url')
          # echo "Resuming healthcheck ${healthcheck-namme} at $RESUME_URL"
          #${pkgs.curl}/bin/curl "$RESUME_URL" --silent -X POST -H "X-Api-Key: $API_KEY"
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

  mkDatabaseBackup = name: attrs: attrs.postgres_databases;
in {
  services.borgbackup.jobs = mapAttrs mkJob cfg;
  systemd.services = mapAttrs' mkHealthCheck cfg;
  systemd.timers = mapAttrs' mkTimerRandomization cfg;
  services.postgresqlBackup.databases = concatLists (mapAttrsToList mkDatabaseBackup cfg);
}
#in mkMerge (mapAttrs create_borg_backup_job cfg.services)

