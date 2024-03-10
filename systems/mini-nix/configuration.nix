# This is your system's configuration file.
# Use this to configure your system environment (it replaces /etc/nixos/configuration.nix)
{
  inputs,
  pkgs,
  ...
}: let
  sshKeys = import ../../common/ssh-keys.nix;
in {
  imports = [
    # If you want to use modules from other flakes (such as nixos-hardware):
    inputs.hardware.nixosModules.common-cpu-intel
    inputs.hardware.nixosModules.common-pc-ssd

    # You can also split up your configuration and import pieces of it here:
    # ./users.nix

    # Import your generated (nixos-generate-config) hardware configuration
    ./hardware-configuration.nix
    ./disk-configuration.nix
    ../defaults.nix
    ../../modules
    ../../services/locate.nix
    ../../services/cache.nix
    ../../services/hercules-ci-agent.nix
    ./ipfs-podcasting.nix
    ./ntfy.nix
    ../../modules/nextdns.nix
    #./mini-nix/nebula.nix
    #../services/seaweedfs.nix
    #../containers/kanidm.nix
    # ../common
  ];

  my.audiobookshelf.enable = true;
  my.backups.services.audiobookshelf.paths = ["/data/audiobookshelf"];
  my.healthchecks = {
    enable = true;
    domain = "healthchecks.eyen.ca";
  };
  my.linkwarden.enable = true;
  my.nextdns.api_secrets.enable = true;
  my.minio = {
    enable = true;
    console_address = "minio-web.eyen.ca";
    api_address = "minio-api.eyen.ca";
    data_dirs = ["/data/minio"];
    region = "mini-nix";
  };
  my.librechat.enable = true;
  my.docker.tools = {
    it-tools.enable = true;
    actual-budget.enable = true;
  };
  my.stirling-pdf.enable = true;
  my.tailscale.enable = true;
  my.vaultwarden.enable = true;
  my.backups.paths = ["/home/eric/git"];
  #my.programs.grafana.enable = false;
  my.programs.upload-to-nix-cache-script.enable = true;

  virtualisation.arion.backend = "docker";

  environment.pathsToLink = ["/share/zsh"];

  # build job concurrency
  nix.settings = {
    max-jobs = 4;
    cores = 8;
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
      shell = pkgs.unstable.zsh;
      openssh.authorizedKeys.keys = sshKeys;
    };
  };
  programs.zsh.enable = true;
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
  #container.adguard = {
  #  bridge = {
  #    name = "br-adguard";
  #    address = "10.100.0.1";
  #    prefixLength = 24;
  #  };
  #  nginx.domain.name = "mini-nix-adguard.eyen.ca";
  #  openFirewall = true;
  #};

  #container.builder = {
  #  bridge = {
  #    name = "br-builder";
  #    address = "10.100.1.1";
  #    prefixLength = 24;
  #  };
  #};

  environment.systemPackages = with pkgs; [nmap dig entr];
  programs.nix-ld.enable = true; # needed for codeium
  programs.mosh.enable = true;

  services.nginx.virtualHosts."unraid.eyen.ca" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://192.168.88.19:81";
      proxyWebsockets = true;
    };
  };
}
