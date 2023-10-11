{pkgs, ...}: let
  domain = "jellyfin.eyen.ca";
in {
  imports = [../../modules/nginx.nix];
  services.jellyfin = {
    enable = true;
    package = pkgs.unstable.jellyfin;
  };
  services.nginx.virtualHosts.${domain} = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:8096";
    };
  };
}
