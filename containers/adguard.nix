{ config, pkgs, ... }:
let
  # additional rules for dns on adguard. these are rules for unraid apps and ors work apps
  unraid_apps = import ../common/dns/unraid_apps.nix;
  domain_name = "eyen.ca";
  unraid_home_dns = map (app: { domain = "${app}.${domain_name}"; answer = "192.168.88.19"; }) unraid_apps;
  office_dns = import ../common/dns/office_apps.nix;
in
{
  networking.nat = {
  enable = true;
  internalInterfaces = ["ve-+"];
  externalInterface = "eno1";
  # Lazy IPv6 connectivity for the container
  enableIPv6 = false;
};
  containers.adguard = {
    autoStart = true;
    extraFlags = [ "-U" ]; # for unprivileged
    ephemeral = true; # don't keep track of files modified

    # forward ports for the dns
    forwardPorts = [
      {
        containerPort = 53;
        hostPort = 53;
        protocol = "tcp";
      }
      {
        containerPort = 53;
        hostPort = 53;
        protocol = "udp";
      }
    ];
    config = { config, pkgs, ... }: {
      system.stateVersion = "23.05";
      services.adguardhome = {
        enable = true;
        openFirewall = true;
        settings = {
          bind_port = 3000;
          bind_host = "0.0.0.0";
          users = [{
            name = "eric_adguard";
            password = "$2y$05$cEOh52jIMsMy2QCyCjgUSO2L3NHtjRXCfXiAyB7ioF1xkd.u6l1Tq";
          }];

          dns = {
            port = 53;
            rewrites = [

              { domain = "perforce.lan.theobjects.com"; answer = "192.168.0.37"; }
              { domain = "swarm.lan.theobjects.com"; answer = "192.168.0.37"; }
              { domain = "docs.lan.theobjects.com"; answer = "192.168.0.37"; }
            ] ++ unraid_home_dns ++ office_dns;


          };
          user_rules = [
            # custom rules to filter out additional ads
            "||wd.adcolony.xyz^$important"
            "||is2-ssl.mzstatic.com^$important"
            "||app.appsflyer.com^$important"
            "||a1931.dscgi3.akamai.net^$important"
            "#||e673.dscx.akamaiedge.net^$client=''192.168.88.46''"
            "#||e673.dscx.akamaiedge.net^$client=''192.168.88.46''"
            "||impressions.crossinstall.io^$important"
            "||szeventhub.servicebus.windows.net^$important"
            "||logs.ironsrc.mobi^$important"
            "||logs-01.loggly.com^$important"
            "||hades.getsocial.im^$important"
            "#||p-hyper-hippo-mainserver-815458781.us-west-2.elb.amazonaws.com^$important"
            "||edge.safedk.com^$important"
            "#||apps.mzstatic.com^$important"
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
              url = "https://secure.fanboy.co.nz/fanboy-cookiemonster.txt";
              name = "EasyList Cookie List";
              id = 1665209809;
            }
          ];
          statistics.interval = "1h";
        };
      };
    };
  };
  networking.firewall = {
    # ports needed for dns
    allowedTCPPorts = [ 53 ];
    allowedUDPPorts = [ 53 ];
  };


}
