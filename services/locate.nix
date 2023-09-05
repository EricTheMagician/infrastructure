{
  unstable,
  config,
  ...
}: {
  services.locate = {
    enable = true;
    locate = unstable.plocate;
    # silence the warning
    localuser = null;
  };
}
