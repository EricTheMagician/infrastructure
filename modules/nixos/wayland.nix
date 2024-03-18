{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.wayland;
  inherit (lib) mkEnableOption mkIf;
in {
  options.my.wayland = {
    enable = mkEnableOption "wayland options";
  };
  config = mkIf cfg.enable {
    environment.sessionVariables = {
      # Hint electron apps to use wayland;
      NIXOS_OZONE_WL = "1";
    };
  };
}
