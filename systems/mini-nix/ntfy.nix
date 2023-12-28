{config, ...}: let
  port = "54312";
in {
  sops.secrets."ntfy/env" = {
    sopsFile = ../../secrets/mini-nix/ntfy.env;
    format = "dotenv";
  };
  services.ntfy-sh = {
    enable = true;
    settings = {
      listen-http = "127.0.0.1:${port}";
      attachment-cache-dir = "/var/lib/ntfy-sh/attachments";
      attachment-expiry-duration = "168h"; # a week
      attachment-total-size-limit = "10G";
      base-url = "https://ntfy.eyen.ca";
      auth-default-access = "read-write";
      behind-proxy = true;
      upstream-base-url = "https://ntfy.sh";
    };
  };

  systemd.services.ntfy-sh.serviceConfig = {
    #EnvironmentFile = [
    #  config.sops.secrets."ntfy/env".path
    #];
  };

  services.nginx.virtualHosts."ntfy.eyen.ca" = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://localhost:${port}";
      proxyWebsockets = true;
    };
  };
}
