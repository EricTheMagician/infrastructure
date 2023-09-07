{
  inputs,
  config,
  pkgs,
  ...
}: let
  sshKeys = import ../common/ssh-keys.nix;
in {
  imports = [
    "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
    ../containers/adguard.nix
    ../modules/tailscale.nix 
  ];
  system.stateVersion = "23.05";
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  networking.hostName = "adguard-unraid-lxc";
  # Time zone settings
  time.timeZone = "America/Vancouver";

  # Clean /tmp on boot.
  boot.tmp.cleanOnBoot = true;
  # automatically optimize the Nix store to save space
  # by hard-linking identical files together. These savings
  # add up.
  nix.settings.auto-optimise-store = true;

  # Limit the systemd journal to 100 MB of disk or the
  # last 7 days of logs, whichever happens first.
  services.journald.extraConfig = ''
    SystemMaxUse=100M
    MaxFileSec=7day
  '';

  services.openssh = {
    enable = true;
    settings = {
      # Use keys only. Remove if you want to SSH using password (not recommended)
      PasswordAuthentication = false;

      # Forbid root login through SSH.
      PermitRootLogin = "yes";
    };
  };

  # configure my containers
  container.adguard = {
    bridge = {
      name = "br-adguard";
      address = "10.100.0.1";
      prefixLength = 24;
    };
    nginx.domain.name = "adguard-unraid.eyen.ca";
  };

  networking.nat = {
    enable = true;
    internalInterfaces = [config.container.adguard.bridge.name];
  };
}
