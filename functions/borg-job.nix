{
  paths,
  config,
  user ? "root",
  name,
  patterns ? [],
  startAt ? "weekly",
  keep ? {
    within = "1d"; # Keep all archives from the last day
    daily = 7;
    weekly = 4;
    monthly = 12; # Keep at least one archive for each month
  },
}: {
  inherit paths;
  inherit user;
  inherit patterns;
  inherit startAt;
  # group = "borg-backup";
  doInit = false;
  repo = "ssh://u322294@u322294.your-storagebox.de:23/./borg_repo";
  compression = "auto,zstd";
  archiveBaseName = "${config.networking.hostName}-${name}";
  encryption = {
    mode = "repokey-blake2";
    passCommand = "cat ${config.sops.secrets.BORG_BACKUP_PASSWORD.path}";
  };
  environment = {BORG_RSH = "ssh -i ${config.sops.secrets.BORG_PRIVATE_KEY.path} -p 23";};
  prune.keep = keep;
  persistentTimer = true;
}
