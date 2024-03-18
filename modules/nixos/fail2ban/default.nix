{
  config,
  lib,
  ...
}: let
  cfg = config.my.fail2ban.jails;
  inherit (lib) mkMerge mkOption types mkIf;
in {
  imports = [./nginx.nix];
  options.my.fail2ban.jails = {
    nginx-spam = mkOption {
      type = types.bool;
      default = true;
      description = "Enable the nginx-spam jail that checks for admin and php 404";
    };
  };
}
