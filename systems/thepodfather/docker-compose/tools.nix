let
  port = "43760";
in {
  virtualisation.arion.projects.utils.settings.services = {
    it-tools.service = {
      container_name = "it-tools";
      image = "ghcr.io/corentinth/it-tools:latest";
      restart = "unless-stopped";
      ports = ["${port}:80"];
    };
  };

  services.nginx.virtualHosts."it-tools.eyen.ca" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/".proxyPass = "http://127.0.0.1:${port}/";
  };
}
