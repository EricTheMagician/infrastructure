{
  pkgs,
  config,
  ...
}: let
  sshKeys = import ../../common/ssh-keys.nix;
in {
  imports = [
    # Include the results of the hardware scan.
    ../../modules/nixos
    #./docker-compose/tools.nix
    ./docker-compose/viewtube.nix
    ./docker.machine-disks.nix
    ./hardware-configuration.nix
    ./invidious.nix
    ./peertube.nix
  ];

  my.forgejo.enable = true;
  my.immich = {
    enable = true;
    database.hostname = "100.64.0.18";
  };
  my.jellyfin.enable = true;
  my.lldap.enable = true;
  my.keycloak.enable = true;
  my.nextcloud.enable = true;
  my.tandoor-recipes.enable = true;
  my.sabnzbd.enable = true;
  my.sonarr = {
    enable = true;
    read_write_dirs = ["/var/lib/sabnzbd" "/mnt/unraid/Media/TV"];
  };
  my.radarr = {
    enable = true;
    read_write_dirs = ["/var/lib/sabnzbd" "/mnt/unraid/Media/Movies"];
  };
  my.tailscale.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thepodfather"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  fileSystems."/mnt/unraid" = {
    device = "shares";
    fsType = "virtiofs";
    #options = ["trans=virtio"];
  };

  fileSystems."/var/lib/nextcloud/data" = {
    device = "nextcloud";
    fsType = "virtiofs";
    #options = ["trans=virtio"];
  };

  # Set your time zone.
  time.timeZone = "America/Vancouver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";
  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkbOptions in tty.
  # };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users = {
    users = {
      root.openssh.authorizedKeys.keys = sshKeys;
      thepodfather = {
        #isNormalUser = false;
        isSystemUser = true;
        extraGroups = ["podman"];
        group = "users";
      };
    };
    groups.users = {
      gid = 100; # this is unraid users group
    };
  };

  users.users.eric = {
    isNormalUser = true;
    description = "Eric";
    extraGroups = ["wheel"];
    shell = pkgs.unstable.zsh;
  };

  sops.defaultSopsFile = ../../secrets/thepodfather/default.yaml;

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    openFirewall = true;
  };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  environment.systemPackages = [
    pkgs.unstable.arion
  ];
  virtualisation.docker = {
    enable = true;
    autoPrune.enable = true;
  };

  virtualisation.podman = {
    enable = false;
    #package = pkgs.unstable.podman;
    autoPrune.enable = true;
    dockerSocket.enable = true;
    # Create a `docker` alias for podman, to use it as a drop-in replacement
    dockerCompat = true;

    # Required for containers under podman-compose to be able to talk to each other.
    defaultNetwork.settings.dns_enabled = true;
  };
  #virtualisation.oci-containers.backend = "docker"; # this is only needed for collabora online server

  # default arion to podman socket
  virtualisation.arion.backend = "docker";

  services.postgresql.enableTCPIP = true;
  #networking.firewall.allowedTCPPorts = [5432];
  networking.firewall.interfaces.tailscale0.allowedTCPPorts = [5432 config.services.typesense.settings.server.api-port];
  networking.firewall.extraCommands = ''
    iptables -A INPUT -s 172.16.0.0/12 -p tcp --dport 5432 -j ACCEPT
    iptables -A INPUT -s 172.16.0.0/12 -p tcp --dport ${toString config.services.typesense.settings.server.api-port} -j ACCEPT
  '';
  services.nginx.clientMaxBodySize = "2048m";

  #sops.secrets."nebula/ca-certificate-authority/ca.key" = {
  #  sopsFile = ./secrets/mini-nix/nebula.yaml;
  #  owner = config.users.users.eric.name;
  #  path = "${config.users.users.eric.home}/nebula/ca/ca.key";
  #  mode = "0400";
  #};

  #sops.secrets."nebula/ca-certificate-authority/ca.crt" = {
  #  sopsFile = ./secrets/mini-nix/nebula.yaml;
  #  owner = config.users.users.eric;
  #  path = "${config.users.users.eric.home}/nebula/ca/ca.crt";
  #  mode = "0400";
  #};

  hardware.opengl = {
    enable = true;
    driSupport = true;
  };
  hardware.nvidia = {
    modesetting.enable = true;

    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    open = false;

    # Enable the nvidia settings menu
    nvidiaSettings = false;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  programs.nix-ld.enable = true; # needed for whisper
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
  #services.qemuGuest.enable = true;
}
