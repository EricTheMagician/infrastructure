{unstable, ...}: {
  imports = [../../modules/nginx.nix];
  services.cockpit = {
    enable = true;
    port = 9090;
    package = unstable.cockpit;
    settings = {
      WebService = {
        Origins = "https://pit.eyen.ca";
        ProtocolHeader = "X-Forwarded-Proto";
        ForwardedForHeader = "X-Forwarded-For";
      };
    };
  };
  services.nginx.virtualHosts."pit.eyen.ca" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:9090";
      proxyWebsockets = true;
    };
  };
}
