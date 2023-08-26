let
  mini-nix.home = "192.168.88.23";
  mini-nix.ts = "100.64.0.16";

  nixos-workstation.home = "192.168.88.14";

  unraid_apps = import ./unraid_apps.nix;
  unraid.home = "192.168.88.19";
  unraid.ts = "100.64.0.2";

  headscale.ts = "100.64.0.1";

in
[
  {
    domain = "mini-nix";
    home = mini-nix.home;
    ts = mini-nix.ts;
  }
  {
    domain = "nixos-workstation";
    home = nixos-workstation.home;
  }
  {
    domain = "headscale.eyen.ca";
    ts = "headscale.ts";
  }
  {
    domain = "unraid.eyen.ca";
    home = "192.168.88.19";
    ts = "100.64.0.2";
  }

] ++ (map (app: { domain = "${app}.eyen.ca"; home = unraid.home; ts = unraid.ts; }) unraid_apps) 
