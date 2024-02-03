{
  paths,
  config,
  user ? "root",
  name,
  patterns ? [],
  startAt ? "weekly",
  keep ? {
    within = "7d"; # Keep all archives from the last day
    daily = 14;
    weekly = 8;
    monthly = 12; # Keep at least one archive for each month
  },
  repo_name ? config.networking.hostName,
}: {
  inherit paths;
  inherit user;
  inherit patterns;
  inherit startAt;
  # group = "borg-backup";
  doInit = true;
  repo = "ssh://borg@100.64.0.10/./${repo_name}";
  compression = "auto,zstd";
  archiveBaseName = "${config.networking.hostName}-${name}";
  encryption = {
    mode = "repokey-blake2";
    passCommand = "cat ${config.sops.secrets."borg/password".path}";
  };
  environment = {BORG_RSH = "ssh -i ${config.sops.secrets."borg/private_key".path}";};
  prune.keep = keep;
  persistentTimer = true;
  environment = {
    #BORG_RELOCATED_REPO_ACCESS_IS_OK = "yes";
  };
}
