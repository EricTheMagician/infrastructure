{
  pkgs,
  config,
  ...
}: let
  sshKeys = import ../../common/ssh-keys.nix;
in {
  imports = [
    # Include the results of the hardware scan.
    ./docker.machine-hardware.nix
    ./docker.machine-disks.nix
    ../../modules/tailscale.nix
    ../../services/acme-default.nix
    ./forgejo.nix
    ./jellyfin.nix
    ./keycloak.nix
    ./lldap.nix
    ./nextcloud.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "thepodfather"; # Define your hostname.
  # Pick only one of the below networking options.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # networking.networkmanager.enable = true;  # Easiest to use and most distros use this by default.

  fileSystems."/mnt/unraid" = {
    device = "shares";
    fsType = "9p";
    options = ["trans=virtio"];
  };

  fileSystems."/var/lib/nextcloud/data" = {
    device = "nextcloud";
    fsType = "9p";
    options = ["trans=virtio"];
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

    # Do install the docker CLI to talk to podman.
    # Not needed when virtualisation.docker.enable = true;
    pkgs.unstable.docker-client
  ];
  virtualisation.docker.enable = false;
  virtualisation.podman = {
    enable = true;
    dockerSocket.enable = true;
  };

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

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
