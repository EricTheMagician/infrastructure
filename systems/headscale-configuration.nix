{ config, pkgs, sshKeys, ... }:
let
in
{
  imports = [
    ./headscale-hardware-configuration.nix
    ../modules/headscale.nix
    ../common
  ];

  boot.tmp.cleanOnBoot = true;
  system.stateVersion = "22.11";
  zramSwap.enable = false;
  networking.hostName = "racknerd-08df0e";
  networking.domain = "";
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  services.openssh = {
    enable = true;
    openFirewall = true;
    listenAddresses = [
      {
        addr = "100.64.0.1"; # headscale ip address
        port = 22;
      }
    ];
    settings.PasswordAuthentication = false;
  };

  environment.systemPackages = with pkgs; [
    neovim
    tmux
    byobu
    btop
  ];
  #users.mysql = {
  #     host = "localhost";
  #};
  #services.mysql = {
  #     package = pkgs.mariadb;
  #       enable = true;
  #       dataDir = "/var/lib/mysql";
  #       ensureDatabases = [
  #               "headscale"
  #       ];
  #       ensureUsers = [
  #       {
  #               name = "headscale";
  #               ensurePermissions = {
  #                       "headscale.*" = "ALL PRIVILEGES";
  #               };
  #       }
  #       ];
  # };
  #  services.headscale = {
  #       enable = false;
  #       derp.autoUpdate = true;
  #       port = 443;
  #  };
  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
  };
}
