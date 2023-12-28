{lib, ...}: let
  it-tools-port = "43760";
  actual-port = "22600";
  inherit (lib) mkMerge;
in
  mkMerge [
    {
      virtualisation.arion.projects.utils.settings.services = {
        it-tools.service = {
          container_name = "it-tools";
          image = "ghcr.io/corentinth/it-tools:latest";
          restart = "unless-stopped";
          ports = ["${it-tools-port}:80"];
        };
      };

      services.nginx.virtualHosts."it-tools.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${it-tools-port}/";
      };
    }
    {
      virtualisation.arion.projects.utils.settings.services = {
        actual-server.service = {
          container_name = "actual-server";
          image = "docker.io/actualbudget/actual-server:latest";
          restart = "unless-stopped";
          ports = ["${actual-port}:5006"];
          volumes = [
            "/var/lib/actual-server/:/data"
          ];
        };
      };
      services.nginx.virtualHosts."budget.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/".proxyPass = "http://127.0.0.1:${actual-port}/";
      };
      my.backup_paths = ["/var/lib/actual-server"];
    }
  ]
