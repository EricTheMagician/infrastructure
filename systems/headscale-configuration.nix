{
  config,
  pkgs,
  ...
}: let
  sshKeys = import ../common/ssh-keys.nix;
in {
  imports = [
    ../common
    ../modules/borg.nix
    ../modules/headscale.nix
    ../modules/tailscale.nix
    ./headscale-hardware-configuration.nix
    #../containers/adguard.nix
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
  ## configure my containers
  #container.adguard = {
  #  bridge = {
  #    name = "br-adguard";
  #    address = "10.100.0.1";
  #    prefixLength = 24;
  #  };
  #  openFirewall = false;
  #};
  #nginx.enable = false;

  #networking.firewall.interfaces.tailscale0 = {
  #  allowedTCPPorts = [53];
  #  allowedUDPPorts = [53];
  #};

  #networking.nat = {
  #  enable = true;
  #  internalInterfaces = pkgs.lib.mapAttrsToList (name: value: value.bridge.name) config.container;
  #};

  ## ensures that the bridges are automatically started by systemd when the container starts
  ## this is needed when just doing a `rebuild switch`. Otherwise, a reboot is fine.
  #systemd.services =
  #  pkgs.lib.mapAttrs' (name: value: {
  #    name = "${value.bridge.name}-netdev";
  #    value = {wantedBy = ["container@${name}.service"];};
  #  })
  #  config.container;
}
