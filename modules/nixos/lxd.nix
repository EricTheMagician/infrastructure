{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkOption mkEnableOption types;
  cfg = config.my.lxd;
in {
  options.my.lxd = {
    enable = mkEnableOption "lxd";
  };
  config = mkIf cfg.enable {
    virtualisation.lxd = {
      enable = true;
      ui.enable = true;
      recommendedSysctlSettings = true;
    };
    virtualisation.lxc = {
      lxcfs.enable = true;
    };
  };
}
