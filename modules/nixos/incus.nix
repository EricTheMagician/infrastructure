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
  disabledModules = ["virtualisation/incus.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/virtualisation/incus.nix")];
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
}
