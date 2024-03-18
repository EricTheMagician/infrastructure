{
  my.fail2ban.jails = {
    nginx-spam = true;
  };
  services.fail2ban.enable = true;
  services.fail2ban.bantime-increment = {
    enable = true;
    maxtime = "168h"; # 7 days
    overalljails = true;
  };
}
