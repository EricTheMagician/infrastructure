{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;
in {
  config = mkIf config.my.fail2ban.jails.nginx-spam {
    environment.etc = {
      "fail2ban/filter.d/nginx-bruteforce.conf".text = ''
        [Definition]
        failregex = ^<HOST>.*GET.*(matrix/server|\.php|admin|wp\-).* HTTP/\d.\d\" 404.*$
                    ^<HOST>.* 400 \d+ "-" "-"$
                    ^<HOST>.* 444 0 .*$
      '';
    };
    services.fail2ban.jails = {
      # max 6 failures in 600 seconds
      "nginx-spam" = ''
        enabled  = true
        filter   = nginx-bruteforce
        logpath = /var/log/nginx/access.log
        backend = auto
        maxretry = 6
        findtime = 600
      '';
    };
  };
}
