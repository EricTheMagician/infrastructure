{
  self,
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  services.tailscale = {
    enable = true;
    overrideLocalDns = true;
  };
  environment.systemPackages = [
    pkgs.vim
    pkgs.alacritty
    pkgs.btop
  ];

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;
  nix.package = pkgs.nix;

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
      trusted-users = ["root" "@wheel"];
      trusted-public-keys = [
        "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
        "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
      max-jobs = 4;
      cores = 8;
    };
  };

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs.zsh.enable = true; # default shell on catalina
  programs.bash.enable = true;
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = self.rev or self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
  # my system configuration
  system = {
    startup.chime = false;
    defaults = {
      trackpad = {
        # Whether to enable trackpad tap to click. The default is false.
        Clicking = true;
        # Whether to enable trackpad right click. The default is false.
        TrackpadRightClick = true;
      };
      # Allow users to login to the machine as guests using the Guest account. Default is true.
      loginwindow.GuestEnabled = false;
      finder = {
        # Whether to always show file extensions. The default is false.
        AppleShowAllExtensions = true;
        # Whether to always show hidden files. The default is false.
        AppleShowAllFiles = true;
      };
    };
  };
  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}
