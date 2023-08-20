# To update the home dns, you should update this file.
# As of now, the dns entries should be modified here to affect both 
# the Tailscale / Headscale dns as well as the home aguard server 

# When you add a new app, you should add it to the list of my_unraid_apps
{ ... }:
let
  unraid_apps = import "./dns/unraid_apps.nix";
  unraid_home_dns = import "./dns/map_to_adguard.nix" { apps = unraid_apps; ip = "192.168.0.19"; };

  my_domain_name = "eyen.ca";
  unraid_host_ts = "100.64.0.2";
  unraid_host_lan = "192.168.88.19";
  ors_office_lan_ip = "192.168.0.37";
  # function to map a name and ip to the tailscale format
  make_headscale_DNS_entry = name: ip: {
    inherit name; # this means `name = name` but this is a syntax that GPT suggested
    type = "A";
    value = ip;
  };
  make_adguard_DNS_entry = name: ip: {
    domain = name;
    answer = ip;
  };


in
{

  tailscale_dns_entries = [
    (make_headscale_DNS_entry "headscale.${my_domain_name}" "100.64.0.1")
    (make_headscale_DNS_entry "adguard-unraid-lxc.${my_domain_name}" "100.64.0.9")
    # TODO
  ]
    #++(map(app: make_headscale_DNS_entry( "${app}.${my_domain_name}" unraid_host_ts)) my_unraid_apps) 
  ;

  adguard_dns_entries = [
    # office ips
    (make_adguard_DNS_entry "ors-ftp3" "192.168.0.25")
    (make_adguard_DNS_entry "builder1-linux" "192.168.0.31")
    (make_adguard_DNS_entry "builder1-windows" "192.168.0.31") # TODO: Check the ip address
    (make_adguard_DNS_entry "vm-builder1-linux" "vm-builder1-linux.lan.theobjects.com")
  ]
  ++ unraid_home_dns
  ;


}
