_: let
  data_path = "/var/lib/viewtube";
in {
  my.nginx.enable = true;
  my.acme.enable = true;
  virtualisation.arion.projects.viewtube.settings.services = {
    viewtube.service = {
      image = "mauriceo/viewtube:latest";
      restart = "unless-stopped";
      depends_on = ["mongodb" "redis"];
      volumes = [
        "${data_path}/data/viewtube:/data"
      ];
      environment = {
        VIEWTUBE_DATABASE_HOST = "mongodb";
        VIEWTUBE_REDIS_HOST = "redis";
        VIEWTUBE_SECURE = "true";
        #VIEWTUBE_PROXY_URL = "viewtube.eyen.ca";  # this parameter is for  an actual proxy like squid and not nginx
      };
      # dns = import ../../../common/dns/podman_dns.nix;
      ports = [
        "8066:8066"
      ];
    };
    mongodb.service = {
      restart = "unless-stopped";
      image = "mongo:5";
      volumes = [
        "${data_path}/data/db:/data/db"
      ];
    };
    redis.service = {
      restart = "unless-stopped";
      image = "redis:7";
      volumes = [
        "${data_path}/data/redis:/data"
      ];
    };
  };
  services.nginx.virtualHosts."viewtube.eyen.ca" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://127.0.0.1:8066";
    };
  };
  my.backups.paths = [data_path];
}
