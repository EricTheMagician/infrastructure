# this script was added to auto start the bridge before the container is started
{
  config,
  lib,
  ...
}: let
  enabaledContriners = lib.filterAttrs (name: value: value.enable) config.my.container;
in {
  # configure container networking
  networking.nat = {
    enable = true;
    internalInterfaces = lib.mapAttrsToList (name: value: value.bridge.name) enabaledContriners;
  };

  # ensures that the bridges are automatically started by systemd when the container starts
  # this is needed when just doing a `rebuild switch`. Otherwise, a reboot is fine.
  systemd.services =
    lib.mapAttrs' (name: value: {
      name = "${value.bridge.name}-netdev";
      value = {wantedBy = ["container@${name}.service"];};
    })
    enabaledContriners;
}
