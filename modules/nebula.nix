# general configuration for nebula
{
  config,
  pkgs,
  lib,
  ...
}: let
  network_name = "home";
in {
  sops.secrets."nebula/ca/ca.crt" = {
    sopsFile = ../secrets/nebula.yaml;
    owner = "nebula-${network_name}";
  };
  services.nebula.networks.${network_name} = {
    ca = config.sops.secrets."nebula/ca/ca.crt".path;
    lighthouses = ["192.168.252.1"];
    package = pkgs.unstable.nebula;
    staticHostMap = {"192.168.252.1" = ["23.94.198.160:4242"];};
    relays = ["192.168.252.1"];
    settings = {
      cipher = "aes";
    };
    firewall.inbound = [
      {
        port = 22;
        proto = "tcp";
        groups = "admin";
      }
    ];
  };
  networking.firewall.allowedUDPPorts = lib.optional config.services.nebula.networks.${network_name}.enable 4242;
}
