{pkgs, ...}: {
  services.locate = {
    enable = true;
    package = pkgs.unstable.plocate;
    # silence the warning
    localuser = null;
  };
}
