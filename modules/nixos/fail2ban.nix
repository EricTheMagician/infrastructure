{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption types mkOption;
  cfg = config.my.fail2ban;
in {
  imports = [./fail2ban];
  options.my.fail2ban = {
    enable = mkEnableOption "fail2ban";
    # for a list of available jails go to modules/fail2ban/
  };

  config = mkIf cfg.enable {
    services.fail2ban.enable = true;
    services.fail2ban.ignoreIP = [
      "100.64.0.0/10"
    ];
    services.fail2ban.bantime-increment = {
      enable = true;
      maxtime = "168h"; # 7 days
      overalljails = true;
    };
  };
}
