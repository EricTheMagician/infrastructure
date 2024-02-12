let
  sshKeys = import ../../common/ssh-keys.nix;
in {
  imports = [
    ../../common
    ../../modules
    ./hardware-configuration.nix
    ./disk-configuration.nix
    ./fail2ban.nix
    #./headscale/nebula.nix
    #../containers/adguard.nix
  ];
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  my.couchdb.enable = true;
  my.headscale.enable = true;
  my.plikd.enable = true;
  my.tailscale.user_name = "headscale";
  my.tailscale.enable = true;
  my.nginx.ban-ip = true;
  boot.tmp.cleanOnBoot = true;
  system.stateVersion = "22.11";
  zramSwap.enable = false;
  networking.hostName = "headscale";
  networking.domain = "";
  users.users.root.openssh.authorizedKeys.keys = sshKeys;

  services.openssh = {
    enable = true;
    openFirewall = true;
    #listenAddresses = [
    #  {
    #    addr = "100.64.0.1"; # headscale ip address
    #    port = 22;
    #  }
    #  #{
    #  #  addr = "192.168.252.1";
    #  #  port = 22;
    #  #}
    #];
    settings.PasswordAuthentication = false;
  };
  services.vnstat.enable = true;
}
