{pkgs, ...}: {
  services.locate = {
    enable = true;
    locate = pkgs.unstable.plocate;
    # silence the warning
    localuser = null;
  };
}
