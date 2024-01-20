{
  sops.secrets."nextdns/api_token" = {
    sopsFile = ../secrets/nextdns.yaml;
  };
  sops.secrets."nextdns/profile/home" = {
    sopsFile = ../secrets/nextdns.yaml;
  };
  sops.secrets."nextdns/profile/tailscale" = {
    sopsFile = ../secrets/nextdns.yaml;
  };
}
