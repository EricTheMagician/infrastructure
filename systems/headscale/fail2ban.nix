{
  imports = [../../modules/fail2ban];
  my.fail2ban.jails = {
    nginx-spam = true;
  };
  services.fail2ban.enable = true;
  services.fail2ban.bantime-increment.enable = true;
  services.fail2ban.bantime-increment.maxtime = "168h"; # 7 days
}
