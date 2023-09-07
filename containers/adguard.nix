{
  config,
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
    ../services/acme-default.nix
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
    services.nginx.virtualHosts.${cfg.nginx.domain.name} = {
      useACMEHost = "eyen.ca";
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
