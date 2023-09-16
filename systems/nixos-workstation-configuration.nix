# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  unstable,
  inputs,
  lib,
  ...
}: let
in {
  imports = [
    # Include the results of the hardware scan.
    ./nixos-workstation-hardware-configuration.nix
    ../modules/tailscale.nix
    ../modules/builder.nix
    #../services/hercules-ci-agent.nix
  ];
  tailscale.secrets_path = ../secrets/tailscale/eric.yaml;
  tailscale.extraUpFlags = [];
  # networking.useNetworkd = true;

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
        "https://minio-api.eyen.ca/nix-cache"
        "https://nix-community.cachix.org"
        "https://cache.nixos.org/"
      ];
      trusted-public-keys = [
        "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];

      # download in parallel from nix-cache
      #max-substitution-jobs = 32;
      trusted-users = ["eric"];
      max-jobs = 16;
      cores = 8;
    };
  };

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  # boot.loader.efi.efiSysMountPoint = "/boot";

  networking.hostName = "nixos-workstation"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Enable networking
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "America/Vancouver";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Configure keymap in X11
  services.xserver = {
    layout = "us";
    xkbVariant = "";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable nvidia drivers
  # Make sure opengl is enabled
  hardware.opengl = {
    enable = true;
    driSupport = true;
    # driSupport32Bit = true;
  };

  # Tell Xorg to use the nvidia driver (also valid for Wayland)
  services.xserver.videoDrivers = ["nvidia"];

  hardware.nvidia = {
    # Modesetting is needed for most Wayland compositors
    modesetting.enable = true;

    # Use the open source version of the kernel module
    # Only available on driver 515.43.04+
    open = false;

    # Enable the nvidia settings menu
    nvidiaSettings = true;

    # Optionally, you may need to select the appropriate driver version for your specific GPU.
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  programs.fish.enable = true;

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.eric = {
    isNormalUser = true;
    description = "Eric";
    extraGroups = ["networkmanager" "wheel" "plocate" "libvirtd"];
    shell = pkgs.bash;
    packages = with pkgs; [
      unstable.ferdium
      unstable.zoom-us
      unstable.slack
      unstable.teams
      unstable.cmakeWithGui
      ninja
      gcc13
      unstable.jetbrains.pycharm-professional
      unstable.jetbrains.clion
      unstable.vscode.fhs # without managing extensions
      unstable.git
      ansible
      # apache-directory-studio
      #  thunderbird
    ];
  };

  # Enable automatic login for the user.
  services.xserver.displayManager.autoLogin.enable = true;
  services.xserver.displayManager.autoLogin.user = "eric";

  # Workaround for GNOME autologin: https://github.com/NixOS/nixpkgs/issues/103746#issuecomment-945091229
  systemd.services."getty@tty1".enable = false;
  systemd.services."autovt@tty1".enable = false;

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.sessionVariables = {
    # Hint electron apps to use wayland;
    #NIXOS_OZONE_WL = "1";
  };
  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    wpsoffice
    unstable.nomachine-client
    # unstable.thunderbird
    unstable.element-desktop
    bitwarden
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    curl
    wezterm
    unstable.tailscale
    unstable.networkmanager-openvpn
    nvtop
    btop
    direnv
    # (python3.withPackages(ps: with ps; [conda]))
    # micromamba
    # build environment for dragonfly
    unstable.p4v
    unstable.p4
    pkg-config
    # build dependencies for dragonfly
    conda
    mesa
    libglvnd
    rustdesk
    virt-manager # kvm management
    xclip # for vim clipboard
  ];
  programs.nix-ld.enable = true;

  programs.nix-index = {
    enable = true;
    enableBashIntegration = false;
    enableZshIntegration = false;
  };

  # enable rootless docker
  virtualisation.docker = {
    enableNvidia = true;
    rootless = {
      enable = true;
      setSocketVariable = true;
    };
  };
  # Note: If you use the btrfs filesystem, you might need to set the storageDriver option:
  # virtualisation.docker.storageDriver = "btrfs";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  services = {
    tailscale = {
      enable = true;
      package = unstable.tailscale;
    };
    locate = {
      enable = true;
      locate = pkgs.plocate;
      localuser = null;
      # interval = "hourly"; # default 02:15
    };
  };

  # kvm virt manager
  virtualisation.libvirtd.enable = true;

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "23.05"; # Did you read the comment?
}
