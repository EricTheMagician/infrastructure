{
  inputs,
  pkgs,
  config,
  ...
}: let
  build_borg_backup_job = import ../functions/borg-job.nix;
in {
  #users.users.kanidm.group = "kanidm";
  #users.groups.kanidm = {};
  #users.groups.borg-backup = {};
  disabledModules = ["services/security/kanidm.nix"];
  imports = [
    (inputs.nixpkgs-unstable + "/nixos/modules/services/security/kanidm.nix")
  ];

  services.borgbackup.jobs.kanidm-server = build_borg_backup_job {
    inherit config;
    paths = [(config.services.kanidm.serverSettings.db_path + "/..")];
    #user = "kanidm";
    name = "kanidm-server";
    patterns = [
      "+ ${config.services.kanidm.serverSettings.db_path}"
      ("- " + (config.services.kanidm.serverSettings.db_path + "/.."))
    ];
    keep = {
      weekly = 4;
      monthly = 3;
    };
  };

  #{
  #  paths = [config.services.kanidm.serverSettings.db_path];
  #  startAt = "weekly";
  #  doInit = false;
  #  repo = "u322294.your-storagebox.de";
  #  compression = "auto,lzma";
  #  encryption = {
  #    mode = "repokey-blake2";
  #    passCommand = "cat ${config.sops.secrets.BORG_BACKUP_PASSWORD.path}";
  #  };
  #  environment = {BORG_RSH = "ssh -i /path/to/ssh_key";};
  #};
  users.users.kanidm.extraGroups = [config.security.acme.defaults.group];
  users.users.kanidm.isSystemUser = true;
  security.acme.certs."login.eyen.ca" = {};
  #systemd.tmpfiles.rules = [
  #  "d /var/lib/private/kanidm  0750 kanidm kanidm 10d"
  #];
  services = {
    kanidm = {
      enableServer = true;
      package = pkgs.unstable.kanidm;
      serverSettings = {
        origin = "https://login.eyen.ca/*";
        domain = "eyen.ca";
        ldapbindaddress = "0.0.0.0:636";
        bindaddress = "127.0.0.1:4443";

        tls_chain = ''${config.security.acme.certs."login.eyen.ca".directory}/fullchain.pem'';
        tls_key = ''${config.security.acme.certs."login.eyen.ca".directory}/key.pem'';
        online_backup = {
          #   The path to the output folder for online backups
          path = "/var/lib/kanidm/backups/";
          #   The schedule to run online backups (see https://crontab.guru/)
          #   every day at 22:00 UTC (default)
          schedule = "00 22 * * *";
          #   Number of backups to keep (default 7)
          versions = 7;
        };
      };
    };
    nginx.virtualHosts."login.eyen.ca" = {
      useACMEHost = "eyen.ca";
      #listen = [
      #  {
      #    addr = "0.0.0.0";
      #    port = 443;
      #  }
      #];
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://127.0.0.1:4443";
        extraConfig = ''
          #proxy_ssl_server_name on;
          proxy_ssl_verify_depth 2;
          proxy_ssl_name $host;
          proxy_ssl_server_name on;
          proxy_ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
          proxy_ssl_session_reuse off;
        '';
      };
    };
  };
  environment.systemPackages = [
    pkgs.unstable.kanidm
  ];
}
