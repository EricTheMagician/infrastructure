{
  config,
  lib,
  ...
}: {
  # configure container networking
  networking.nat = {
    enable = true;
    internalInterfaces = lib.mapAttrsToList (name: value: value.bridge.name) config.container;
  };
  # ensures that the bridges are automatically started by systemd when the container starts
  # this is needed when just doing a `rebuild switch`. Otherwise, a reboot is fine.
  systemd.services =
    lib.mapAttrs' (name: value: {
      name = "${value.bridge.name}-netdev";
      value = {wantedBy = ["container@${name}.service"];};
    })
    config.container;
}
