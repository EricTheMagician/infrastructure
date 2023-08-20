{ config, pkgs, ... }:
# sshKeys = import ../common/ssh-keys.nix;
{
  imports = [
    ../common/adguard.nix
  ];
  system.stateVersion = "23.05";
  # users.users.root.openssh.authorizedKeys.keys = sshKeys;

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

  services.ssh = {
    enable = true;
    openFirewall = true;
    settings.PasswordAuthentication = false;
  };

}
