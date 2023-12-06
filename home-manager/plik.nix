{
  pkgs,
  config,
  lib,
  ...
}: let
  cfg = config.my.programs.plik;
in {
  # module to manage plik
  imports = [./sops.nix];
  options.my.programs.plik = {
    enable = lib.mkEnableOption "if enabled, plik will be configured for the current user";
  };
  config = lib.mkIf cfg.enable {
    home.packages = [pkgs.plik];
    sops.secrets."programs/.plik.cfg" = {
      sopsFile = ../secrets/plik.yaml;
      path = "${config.home.homeDirectory}/.plikrc";
    };
  };
}
