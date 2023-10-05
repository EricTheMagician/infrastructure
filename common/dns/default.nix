# To update the home dns, you should update this file.
# As of now, the dns entries should be modified here to affect both
# the Tailscale / Headscale dns as well as the home aguard server
# When you add a new app, you should add it to the list of my_unraid_apps
let
  custom_domains = import ./custom_domains.nix;
in {
  tailscale_dns_entries =
    builtins.map
    ({
      domain,
      ts,
      ...
    }: {
      name = domain;
      type = "A";
      value = ts;
    })
    (builtins.filter (builtins.hasAttr "ts")
      custom_domains);

  adguard_dns_entries =
    builtins.map
    ({
      domain,
      home,
      ...
    }: {
      inherit domain;
      answer = home;
    })
    (builtins.filter (builtins.hasAttr "home")
      custom_domains);
}
