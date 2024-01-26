let
  ip = "209.209.9.184";
  server_ip = "";
  gateway = "209.209.9.1";
  netmask = "255.255.255.0";
  host = "nixos-rica";
  device = "enX0";
  autoconf = "none";
  dns1 = "1.1.1.1";
in {
  # https://nixos.wiki/wiki/Remote_LUKS_Unlocking
  # Unlock command:
  # ssh root@209.209.9.184 "Password"

  boot.kernelParams = ["ip=${ip}:${server_ip}:${gateway}:${netmask}:${host}:${device}:${autoconf}:${dns1}"];

  boot.initrd = {
    enable = true;
    systemd.users.root.shell = "/bin/cryptsetup-askpass";
    # Enable your network card during initrd. Find what module your network card needs with:
    #   lspci -v | grep -iA8 'network\|ethernet'
    availableKernelModules = ["cdc_ncm"];
    network.enable = true;
    network.ssh = {
      enable = true;
      port = 22;
      authorizedKeys = import ../../common/ssh-keys.nix;
      hostKeys = [
        # Generate new keys with:
        #   ssh-keygen -t ed25519 -N "" -f /boot/ssh_host_rsa_key
        "/boot/ssh_host_ed25519_key"
      ];
    };
  };
}
