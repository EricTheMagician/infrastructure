# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  unstable,
  ...
}: let
  sshKeys = import ../common/ssh-keys.nix;
  build_borg_backup_job = import ../functions/borg-job.nix;
in {
  disabledModules = ["services/security/kanidm.nix"];
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    (inputs.nixpkgs-unstable + "/nixos/modules/services/security/kanidm.nix")
    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./mini-nix-hardware-configuration.nix
    ./mini-nix-disks.nix
    ../containers/adguard.nix
    ../modules/kanidm-admin.nix
    ../modules/kanidm-client.nix
    ../modules/borg.nix
    ../modules/tailscale.nix
    ../modules/knownHosts.nix
    ../services/healthchecks.nix
    ../services/locate.nix
    #../containers/kanidm.nix
    # ../common
  ];
  nixpkgs = {
    # You can add overlays here
    overlays = [
      # If you want to use overlays exported from other flakes:
      # neovim-nightly-overlay.overlays.default

      # Or define it inline, for example:
      # (final: prev: {
      #   hi = final.hello.overrideAttrs (oldAttrs: {
      #     patches = [ ./change-hello-to-hi.patch ];
      #   });
      # })
    ];
    # Configure your nixpkgs instance
    config = {
      # Disable if you don't want unfree packages
      allowUnfree = true;
    };
  };

  nix = {
    # This will add each flake input as a registry
    # To make nix3 commands consistent with your flake
    registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

    # This will additionally add your inputs to the system's legacy channels
    # Making legacy nix commands consistent as well, awesome!
    nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

    settings = {
      # Enable flakes and new 'nix' command
      experimental-features = "nix-command flakes";
      # Deduplicate and optimize nix store
      auto-optimise-store = true;
    };
  };

  # Set your hostname
  networking.hostName = "mini-nix";
  # Time zone settings
  time.timeZone = "America/Vancouver";
  # This is just an example, be sure to use whatever bootloader you prefer
  boot.loader.systemd-boot.enable = true;

  # Configure your system-wide user settings (groups, etc), add more users as needed.
  users.users = {
    root = {
      openssh.authorizedKeys.keys = sshKeys;
    };
    eric = {
      isNormalUser = true;
      extraGroups = ["wheel"];
      home = "/home/eric";
      openssh.authorizedKeys.keys = sshKeys;
    };
  };

  # This setups a SSH server. Very important if you're setting up a headless system.
  services.openssh = {
    enable = true;
    settings = {
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;

      # Forbid root login through SSH.
      PermitRootLogin = "no";

      # use kanidm ssh to authorize some of my keys
      AuthorizedKeysCommand = "${unstable.kanidm}/bin/kanidm_ssh_authorizedkeys %u";
      AuthorizedKeysCommandUser = "kanidm";
    };
  };

  # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = "23.05";

  # configure my containers
  container.adguard = {
    bridge = {
      name = "br-adguard";
      address = "10.100.0.1";
      prefixLength = 24;
    };
    nginx.domain.name = "mini-nix-adguard.eyen.ca";
  };

  # configure my containers
  #container.kanidm = {
  #  bridge = {
  #    name = "br-kanidm";
  #    address = "10.100.1.1";
  #    prefixLength = 24;
  #  };
  #  nginx.domain.name = "login.eyen.ca";
  #};

  #users.users.kanidm.group = "kanidm";
  #users.groups.kanidm = {};
  #users.groups.borg-backup = {};
  services.borgbackup.jobs.kanidm-server = build_borg_backup_job {
    inherit config;
    paths = [(builtins.toPath (config.services.kanidm.serverSettings.db_path + "/.."))];
    #user = "kanidm";
    name = "kanidm-server";
    patterns = [
      "+ ${config.services.kanidm.serverSettings.db_path}"
      ("- " + (builtins.toPath (config.services.kanidm.serverSettings.db_path + "/..")))
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
  systemd.tmpfiles.rules = [
    #  "d /var/lib/private/kanidm  0750 kanidm kanidm 10d"
  ];
  services.kanidm = {
    enableServer = true;
    package = unstable.kanidm;
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
  services.nginx.virtualHosts."login.eyen.ca" = {
    useACMEHost = "login.eyen.ca";
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
  environment.systemPackages = [
    unstable.kanidm
  ];

  networking.nat = {
    enable = true;
    internalInterfaces = lib.mapAttrsToList (name: value: value.bridge.name) config.container;
  };

  # ensures that the bridges are automatically started by systemd when the container starts
  # this is needed when just doing a `rebuild switcch`. Otherwise, a reboot is fine.
  systemd.services =
    lib.mapAttrs' (name: value: {
      name = "${value.bridge.name}-netdev";
      value = {wantedBy = ["container@${name}.service"];};
    })
    config.container;
}
