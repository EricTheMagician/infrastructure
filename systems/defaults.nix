{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: let
  inherit ((import ../home-manager/zsh_config.nix)) zsh;
in {
  # disable building the documentation
  documentation.nixos.enable = false;

  nix = {
    # Automatically run the garbage collector at a specific time.
    gc.automatic = true;
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
    };
  };
  programs.zsh = {
    enable = true;
    autosuggestions = {enable = true;};
    ohMyZsh = zsh.oh-my-zsh;
  };
  programs.fzf = {
    fuzzyCompletion = true;
    keybindings = true;
  };

  programs.neovim = {
    enable = true;
    defaultEditor = true;
    vimAlias = true;
    viAlias = true;
  };

  environment.systemPackages = [
    pkgs.unstable.thefuck
    pkgs.unstable.tmux
    pkgs.unstable.zoxide
    pkgs.pigz
    pkgs.pixz
    pkgs.unstable.ripgrep
    pkgs.unstable.fd
    pkgs.unstable.dua
    pkgs.unstable.bat
    pkgs.unstable.btop
  ];
}
