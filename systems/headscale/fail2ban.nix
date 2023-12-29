{
  imports = [../../modules/fail2ban];
  my.fail2ban.jails = {
    nginx-spam = true;
  };
}
