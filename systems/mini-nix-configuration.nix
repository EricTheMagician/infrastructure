# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  lib,
  config,
  unstable,
  pkgs,
  ...
}: let
  sshKeys = import ../common/ssh-keys.nix;
in {
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./mini-nix-hardware-configuration.nix
    ./mini-nix-disks.nix
    ../containers/adguard.nix
    #../containers/builder.nix
    ../modules/borg.nix
    ../modules/tailscale.nix
    ../modules/knownHosts.nix
    ../modules/builder.nix
    ../services/healthchecks.nix
    ../services/locate.nix
    ../services/cache.nix
    ../modules/minio.nix
    ../services/hercules-ci-agent.nix
    #../services/seaweedfs.nix
    #../containers/kanidm.nix
    # ../common
  ];

  services.minio.region = "mini-nix";
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
      substituters = [
        "s3://nix-cache?region=mini-nix&scheme=https&endpoint=minio-api.eyen.ca"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      max-jobs = 8;
      cores = 2;
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
      PermitRootLogin = "yes";

      # use kanidm ssh to authorize some of my keys
      #AuthorizedKeysCommand = "${unstable.kanidm}/bin/kanidm_ssh_authorizedkeys %u";
      #AuthorizedKeysCommandUser = "kanidm";
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

  #container.builder = {
  #  bridge = {
  #    name = "br-builder";
  #    address = "10.100.1.1";
  #    prefixLength = 24;
  #  };
  #};

  # configure my containers

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
