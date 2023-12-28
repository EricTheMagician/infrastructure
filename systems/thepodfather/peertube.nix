{
  pkgs,
  config,
  ...
}: let
  peertube_secret_settings = {
    sopsFile = ../../secrets/peertube.yaml;
    owner = "peertube";
  };
in {
  sops.secrets."peertube/db_password" = peertube_secret_settings;
  sops.secrets."peertube/secret" = peertube_secret_settings;

  services.peertube = {
    enable = true;
    package = pkgs.unstable.peertube;
    configureNginx = true;
    localDomain = "peertube.eyen.ca";
    enableWebHttps = true;
    listenWeb = 443;
    dataDirs = [
      "/mnt/unraid/PeerTube/data"
    ];
    redis = {
      createLocally = true;
      enableUnixSocket = true;
    };
    secrets.secretsFile = config.sops.secrets."peertube/secret".path;
    database = {
      createLocally = true;
      passwordFile = config.sops.secrets."peertube/db_password".path;
    };
    settings = {
      smtp = {
        username = "eric@ericyen.com";
        hostname = "smtp.fastmail.com";
        from_address = "peertube@ericyen.com";
        port = 465;
        tle = true;
      };
      storage = {
        logs = "/mnt/unraid/PeerTube/data/logs/";
        #tmp = "/mnt/unraid/PeerTube/data/tmp/";
        tmp_persistent = "/mnt/unraid/PeerTube/data/tmp-persistent/";
        bin = "/mnt/unraid/PeerTube/data/bin/";
        avatars = "/mnt/unraid/PeerTube/data/avatars/";
        videos = "/mnt/unraid/PeerTube/data/videos/";
        streaming_playlists = "/mnt/unraid/PeerTube/data/streaming-playlists/";
        redundancy = "/mnt/unraid/PeerTube/data/redundancy/";
        previews = "/mnt/unraid/PeerTube/data/previews/";
        thumbnails = "/mnt/unraid/PeerTube/data/thumbnails/";
        storyboards = "/mnt/unraid/PeerTube/data/storyboards/";
        torrents = "/mnt/unraid/PeerTube/data/torrents/";
        captions = "/mnt/unraid/PeerTube/data/captions/";
        cache = "/mnt/unraid/PeerTube/data/cache/";
        plugins = "/mnt/unraid/PeerTube/data/plugins/";
        well_known = "/mnt/unraid/PeerTube/data/well-known/";
        # Overridable client files in client/dist/assets/images =
        # - logo.svg
        # - favicon.png
        # - default-playlist.jpg
        # - default-avatar-account.png
        # - default-avatar-video-channel.png
        # - and icons/*.png (PWA)
        # Could contain for example assets/images/favicon.png
        # If the file exists, peertube will serve it
        # If not, peertube will fallback to the default file
        client_overrides = "/mnt/unraid/PeerTube/data/client-overrides/";
      };
    };
  };
  systemd.services.peertube.path = [pkgs.unstable.yt-dlp];
  services.nginx.virtualHosts."${config.services.peertube.localDomain}" = {
    forceSSL = true;
    useACMEHost = "eyen.ca";
  };
  my.backup_paths = ["/mnt/unraid/PeerTube/data"];
}
