{
  bind_port = 3000;
  bind_host = "0.0.0.0";
  users = [
    {
      name = "eric_adguard";
      password = "$2y$05$cEOh52jIMsMy2QCyCjgUSO2L3NHtjRXCfXiAyB7ioF1xkd.u6l1Tq";
    }
  ];

  dns = {
    port = 53;
    rewrites = (import ../../common/dns).adguard_dns_entries;
  };

  cache_ttl_min = 60 * 60 * 4;
  cache_ttl_max = 60 * 60 * 24 * 4;

  user_rules = [
    # custom rules to filter out additional ads
    "||wd.adcolony.xyz^$important"
    "||is2-ssl.mzstatic.com^$important"
    "||app.appsflyer.com^$important"
    "||a1931.dscgi3.akamai.net^$important"
    "||impressions.crossinstall.io^$important"
    "||szeventhub.servicebus.windows.net^$important"
    "||logs.ironsrc.mobi^$important"
    "||logs-01.loggly.com^$important"
    "||hades.getsocial.im^$important"
    "#||p-hyper-hippo-mainserver-815458781.us-west-2.elb.amazonaws.com^$important"
    "||edge.safedk.com^$important"
    "#||apps.mzstatic.com^$important"
  ];

  upstream_dns = [
    "1.1.1.1"
  ];
  bootstrap_dns = [
    "1.1.1.1"
  ];

  # the filters list
  filters = [
    {
      enabled = true;
      url = "https://adguardteam.github.io/AdGuardSDNSFilter/Filters/filter.txt";
      name = "AdGuard DNS filter";
      id = 1;
    }
    {
      enabled = true;
      url = "https://adaway.org/hosts.txt";
      name = "AdAway Default Blocklist";
      id = 2;
    }
    {
      enabled = true;
      url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_24.txt";
      name = "1Hosts (Lite)";
      id = 24;
    }
    {
      enabled = true;
      url = "https://adguardteam.github.io/HostlistsRegistry/assets/filter_30.txt";
      name = "PhishTank and OpenPhish";
      id = 30;
    }
    {
      enabled = true;
      url = "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt";
      name = "EasyList Cookie List";
      id = 1665209809;
    }
  ];
  statistics.interval = "1h";
}
