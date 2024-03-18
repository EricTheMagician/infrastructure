# general configuration for nebula
{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  network_name = "home";
  cfg = config.services.nebula.networks.${network_name};
in {
  options.my.nebula = {
    enable = mkEnableOption "nebula";
  };
  config = mkIf config.my.nebula.enable {
    sops.secrets."nebula/ca/ca.crt" = {
      sopsFile = ../../secrets/nebula.yaml;
      owner = "nebula-${network_name}";
    };
    services.nebula.networks.${network_name} = {
      ca = config.sops.secrets."nebula/ca/ca.crt".path;
      lighthouses = lib.optionals (!cfg.isLighthouse) ["192.168.252.1"];
      relays = lib.optionals (!cfg.isRelay) ["192.168.252.1"];
      package = pkgs.unstable.nebula;
      staticHostMap = lib.optionalAttrs (!cfg.isLighthouse) {"192.168.252.1" = ["23.94.198.160:4242"];};
      settings = {
        cipher = "aes";
        firewall = {
          conntrack = {
            tcp_timeout = "12m";
            udp_timeout = "3m";
            default_timeout = "10m";
            max_connections = 100000;
          };
        };
      };
      firewall.outbound = [
        {
          proto = "any";
          port = "any";
          host = "any";
        }
      ];
      firewall.inbound = [
        #{
        #  port = 22;
        #  proto = "tcp";
        #  groups = ["admin"];
        #}
        {
          port = "any";
          proto = "icmp";
          host = "any";
        }
        {
          port = 22;
          proto = "tcp";
          groups = ["admin"];
        }
      ];
    };
    networking.firewall.allowedUDPPorts = lib.optional config.services.nebula.networks.${network_name}.enable 4242;
  };
}
