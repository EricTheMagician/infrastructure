{
  config,
  pkgs,
  lib,
  ...
}: let
  net = (import ../common/net.nix {inherit lib;}).lib.net;
  inherit (lib) mkOption mkIf types;
  adguard_settings = import ./settings/adguard.nix;
  cfg = config.container.adguard;
  # this is the ip we need to expose
  containerIp = net.ip.add 1 cfg.bridge.address;
in {
  imports = [
    ../common/net.nix
    ../modules/nginx.nix
  ];
  options.container.adguard = {
    bridge = {
      name = mkOption {type = types.str;};
      address = mkOption {
        type = types.str;
      };
      prefixLength = mkOption {type = types.int;};
    };
    nginx.domain.name = mkOption {
      type = types.str;
    };
  };

  config = {
    # create the network bridge from the host to the container
    networking = {
      bridges.${cfg.bridge.name}.interfaces = [];
      interfaces.${cfg.bridge.name}.ipv4.addresses = [
        {
          address = cfg.bridge.address;
          prefixLength = cfg.bridge.prefixLength;
        }
      ];
      firewall = {
        # ports needed for dns
        allowedTCPPorts = [53];
        allowedUDPPorts = [53];
      };
    };

    # create the nginx virtual host and security certificates
    security.acme.certs.${cfg.nginx.domain.name} = {};
    services.nginx.virtualHosts.${cfg.nginx.domain.name} = {
      useACMEHost = cfg.nginx.domain.name;
      forceSSL = true;
      locations."/" = {
        proxyPass = "http://${containerIp}:3000";
      };
    };

    # create the adguard container

    containers.adguard = {
      autoStart = true;
      extraFlags = ["-U"]; # for unprivileged
      ephemeral = true; # don't keep track of files modified
      privateNetwork = true;
      hostBridge = cfg.bridge.name;
      # forward ports for the dns
      forwardPorts = [
        {
          containerPort = 53;
          hostPort = 53;
          protocol = "tcp";
        }
        {
          containerPort = 53;
          hostPort = 53;
          protocol = "udp";
        }
      ];
      config = {
        system.stateVersion = "23.05";
        networking = {
          interfaces.eth0.ipv4.addresses = [
            {
              # Configure a prefix address.
              address = containerIp;
              prefixLength = cfg.bridge.prefixLength;
            }
          ];
          defaultGateway.address = cfg.bridge.address;
          defaultGateway.interface = "eth0";
          defaultGateway.metric = 0;
        };
        networking.firewall = {
          # ports needed for dns
          allowedTCPPorts = [53];
          allowedUDPPorts = [53];
        };

        services.adguardhome = {
          enable = true;
          openFirewall = true;
          settings = adguard_settings;
        };
      };
    };
  };
}
# { config, pkgs, lib, ... }:
# let
#   hostIp = "10.100.0.1";
#   containerIp = "10.100.0.2";
#   prefixLength = 24;
#   hostIp6 = "fc00::1";
#   containerIp6 = "fc00::2/7";
#   # additional rules for dns on adguard. these are rules for unraid apps and ors work apps
#   adguard_hostname = config.networking.hostName + "-adguard.eyen.ca";
#   adguard_settings = import ./settings/adguard.nix;
# in
# {
#   imports = [
#     ../modules/nginx.nix
#   ];
#   networking = {
#     firewall = {
#       # ports needed for dns
#       allowedTCPPorts = [ 53 ];
#       allowedUDPPorts = [ 53 ];
#     };
#     # nat = {
#     #   enable = true;
#     #   # internalInterfaces = [ "ve-adguard" ];
#     #   # externalInterface = "eno1";
#     #   # Lazy IPv6 connectivity for the container
#     #   enableIPv6 = false;
#     # };
#     bridges.br-adguard.interfaces = [ ];
#     interfaces.br-adguard.ipv4.addresses = [{ address = hostIp; prefixLength = prefixLength; }];
#     interfaces.br-adguard.ipv6.addresses = [{ address = hostIp6; prefixLength = 7; }];
#     interfaces.br-adguard.useDHCP = false;
#     enableIPv6 = false;
#   };
#   # services.nginx.virtualHosts.${adguard_hostname} = {
#   #   useACMEHost = adguard_hostname;
#   #   forceSSL = true;
#   #   locations."/" = {
#   #     proxyPass = "http://ve-adguard:3000";
#   #   };
#   # };
#   security.acme.certs.${adguard_hostname} = { };
#   containers.adguard = {
#     autoStart =  true;
#     # extraFlags = [ "-U" ]; # for unprivileged
#     # ephemeral = true; # don't keep track of files modified
#     privateNetwork = true;
#     hostBridge = "br-adguard";
#     # hostAddress = hostIp;
#     # localAddress = containerIp;
#     # localAddress = containerIp + "/24";
#     # forward ports for the dns
#     # forwardPorts = [
#     #   {
#     #     containerPort = 53;
#     #     hostPort = 53;
#     #     protocol = "tcp";
#     #   }
#     #   {
#     #     containerPort = 53;
#     #     hostPort = 53;
#     #     protocol = "udp";
#     #   }
#     #   {
#     #     containerPort = 3000;
#     #     hostPort = 3000;
#     #     protocol = "tcp";
#     #   }
#     # ];
#     config = {
#       system.stateVersion = "23.05";
#       # for some reason, adguard openfirewall does not open the firewall for the dns port, only the http port
#       networking = {
#         # firewall = {
#         #   # ports needed for dns
#         #   allowedTCPPorts = [ 53 ];
#         #   allowedUDPPorts = [ 53 ];
#         # };
#         interfaces.eth0.useDHCP = false;
#         interfaces.eth0.ipv4.addresses = [{
#           # Configure a prefix address.
#           address = containerIp;
#           prefixLength = prefixLength;
#         }];
#         interfaces.eth0.ipv6.addresses = [{
#           # Configure a prefix address.
#           address = containerIp6;
#           prefixLength = prefixLength;
#         }];
#           # defaultGateway.address = hostIp;
#           # defaultGateway.interface = "eno1";
#           # defaultGateway.metric = 0;
#           # nameservers = ["1.1.1.1"];
#       };
#       # services.adguardhome = {
#       #   enable = true;
#       #   openFirewall = true;
#       #   settings = adguard_settings;
#       # };
#     };
#   };
# }

