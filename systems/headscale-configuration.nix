{
  config,
  pkgs,
  ...
}: let
  sshKeys = import ../common/ssh-keys.nix;
in {
  imports = [
    ./headscale-hardware-configuration.nix
    ../modules/headscale.nix
    ../common
    ../modules/tailscale.nix
  ];

  tailscale.secrets_path = ../secrets/tailscale/headscale.yaml;
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
}
