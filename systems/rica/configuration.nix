# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
    ./disks.nix
    ../defaults.nix
    ./ssh-luks.nix
    ../../modules
  ];
  my.fail2ban.enable = true;
  my.tailscale = {
    enable = true;
  };

  # Use the GRUB 2 boot loader.
  boot.loader.grub.enable = true;
  # boot.loader.grub.efiSupport = true;
  # boot.loader.grub.efiInstallAsRemovable = true;
  # boot.loader.efi.efiSysMountPoint = "/boot/efi";
  # Define on which hard drive you want to install Grub.
  #boot.loader.grub.device = "/dev/xvda"; # or "nodev" for efi only

  # clean garbage automatically
  nix.gc.automatic = true;

  networking.hostName = "nixos-rica"; # Define your hostname.
  # Set your time zone.
  time.timeZone = "America/Vancouver";

  i18n.defaultLocale = "en_CA.UTF-8";

  # Enable the OpenSSH daemon.
  services.openssh.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "22.11"; # Did you read the comment?
}
