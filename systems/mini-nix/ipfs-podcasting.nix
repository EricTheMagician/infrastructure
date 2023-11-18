{pkgs, ...}: {
  programs.ipfs-podcasting = {
    enable = true;
    email = "eric@ipfspodcasting.ericyen.com";
    openFirewall = true;
  };
  services.kubo = {
    package = pkgs.unstable.ipfs;
    dataDir = "/data/ipfs";
  };
}
