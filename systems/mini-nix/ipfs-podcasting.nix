{pkgs, ...}: {
  programs.ipfs-podcasting = {
    enable = true;
    email = "eric@ipfspodcasting.ericyen.com";
    openFirewall = true;
    turbo-mode = true;
  };
  services.kubo = {
    package = pkgs.unstable.ipfs;
    dataDir = "/data/ipfs";
  };
  #boot.kernel.sysctl."net.core.wmem_max" = 2097152;
  boot.kernel.sysctl."net.core.wmem_max" = 2500000;
}
