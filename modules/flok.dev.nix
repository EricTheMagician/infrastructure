{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.my.flox;
in {
  options.my.flox.enable = mkEnableOption "flox";
  config = mkIf cfg.enable {
    nix.settings.extra-trusted-substituters = ["https://cache.flox.dev"];
    nix.settings.extra-trusted-public-keys = ["flox-cache-public-1:7F4OyH7ZCnFhcze3fJdfyXYLQw/aV7GEed86nQ7IsOs="];
    environment.systemPackages = [pkgs.flox];
  };
}
