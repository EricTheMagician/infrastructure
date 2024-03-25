{
  inputs,
  lib,
  config,
  pkgs,
  ...
}: let
  inherit (lib) mkEnableOption mkIf types mkOption;
  cfg = config.my.incus;
in {
  options.my.incus = {
    enable = mkEnableOption "incus";
  };
  config = mkIf cfg.enable {
    disabledModules = ["virtualisation/incus.nix"];
    imports = [(inputs.nixpkgs-unstable + "/nixos/modules/virtualisation/incus.nix")];
    options.my.lxd = {
      enable = mkEnableOption "lxd";
    };
    config = mkIf cfg.enable {
      virtualisation.incus = {
        enable = true;
        package = pkgs.unstable.incus;
        ui = {
          enable = true;
          package = pkgs.unstable.incus.ui;
        };
      };
      virtualisation.lxc = {
        lxcfs.enable = true;
      };
      networking.nftables.enable = true;
    };
  };
}
