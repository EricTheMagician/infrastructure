{
  config,
  options,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit ((import ../common/net.nix {inherit lib;}).lib) net;
  inherit (lib) mkOption mkEnableOption types mkIf mkMerge;
  adguard_settings = import ./settings/adguard.nix;
  cfg-home = config.my.container.adguard-home;
  cfg-ts = config.my.container.adguard-ts;
  # this is the ip we need to expose
  containerIp = net.ip.add 1 cfg-home.bridge.address;
  # microvm = inputs.microvm.nixosModules.microvm;
in {
  options.my.container.adguard-home = {
    enable = mkEnableOption "adguard containers";
    bridge = {
      name = mkOption {type = types.str;};
      address = mkOption {
        type = types.str;
      };
      prefixLength = mkOption {type = types.int;};
    };
    nginx.domain.name = mkOption {
      type = types.str;
      default = "adguard-home.eyen.ca";
    };
    openFirewall = mkEnableOption "if enabled, opens port 53 on network_device";
    host = mkOption {
      type = types.str;
    };
    network_device = mkOption {
      type = types.str;
      default = "eno1";
    };
  };
  options.my.container.adguard-ts = options.my.container.adguard-home;

  config = mkMerge [
    (mkIf cfg-home.enable {
      # create the network bridge from the host to the container
      assertions = [
        {
          assertion = config.networking.firewall.enable && !config.networking.nftables.enable;
          message = "firewall rules are only for ipTables";
        }
      ];
      networking = {
        bridges.${cfg-home.bridge.name}.interfaces = [];
        interfaces.${cfg-home.bridge.name}.ipv4.addresses = [
          {
            inherit (cfg-home.bridge) address prefixLength;
          }
        ];
        firewall = {
          # ports needed for dns
          allowedTCPPorts = lib.optionals cfg-home.openFirewall [53];
          allowedUDPPorts = lib.optional cfg-home.openFirewall 53;
        };
        nat.externalInterface = cfg-home.network_device;
        # firewall.extraCommands = ''
        # nat.extraCommands = ''
        #   # Forward DNS traffic from ${cfg-home.network_device}
        #   iptables -t nat -A PREROUTING -i ${cfg-home.network_device} -p tcp --dport 53 -j DNAT --to-destination ${containerIp}:53
        #   iptables -t nat -A PREROUTING -i ${cfg-home.network_device} -p udp --dport 53 -j DNAT --to-destination ${containerIp}:53
        #
        #   # Enable loopback forwarding for DNS traffic from eno1
        #   iptables -t nat -A OUTPUT -o ${cfg-home.network_device} -p tcp --dport 53 -j DNAT --to-destination ${containerIp}:53
        #   iptables -t nat -A OUTPUT -o ${cfg-home.network_device} -p udp --dport 53 -j DNAT --to-destination ${containerIp}:53
        #
        #   # Allow incoming DNS traffic on the loopback interface
        #   iptables -A INPUT -i lo -p tcp --dport 53 -j ACCEPT
        #   iptables -A INPUT -i lo -p udp --dport 53 -j ACCEPT
        #
        #   # Enable forwarding for the redirected traffic
        #   iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
        #   iptables -A FORWARD -p tcp -d ${containerIp} --dport 53 -j ACCEPT
        #   iptables -A FORWARD -p udp -d ${containerIp} --dport 53 -j ACCEPT
        # '';
      };

      # create the nginx virtual host and security certificates
      services.nginx.virtualHosts.${cfg-home.nginx.domain.name} = {
        # useACMEHost = "eyen.ca";
        useACMEHost = cfg-home.nginx.domain.name;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://${containerIp}:3000";
        };
      };
      security.acme.certs.${cfg-home.nginx.domain.name} = {};

      # setup the adguard networking
      # networking.nat.forwardPorts = [
      # {proto = "tcp";

      # create the adguard container

      containers.adguard-home = {
        inherit (inputs) nixpkgs;
        autoStart = true;
        extraFlags = ["-U"]; # for unprivileged
        # ephemeral = true; # don't keep track of files modified
        privateNetwork = true;
        hostBridge = cfg-home.bridge.name;
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
          nixpkgs = {inherit pkgs;};
          system.stateVersion = "23.05";
          networking = {
            interfaces.eth0.ipv4.addresses = [
              {
                # Configure a prefix address.
                address = containerIp;
                inherit (cfg-home.bridge) prefixLength;
              }
            ];
            defaultGateway = {
              inherit (cfg-home.bridge) address;
              interface = "eth0";
              metric = 0;
            };
          };
          networking.firewall = {
            # ports needed for dns and gui
            allowedTCPPorts = [53 3000];
            allowedUDPPorts = [53];
          };

          services.adguardhome = {
            enable = true;
            openFirewall = true;
            settings = adguard_settings;
          };
        };
      };
    })

    # (mkIf cfg-ts.enable {
    #   # create the network bridge from the host to the container
    #   assertions = [
    #     {
    #       assertion = config.networking.firewall.enable && !config.networking.nftables.enable;
    #       message = "firewall rules are only for ipTables";
    #     }
    #   ];
    #   networking = {
    #     bridges.${cfg-ts.bridge.name}.interfaces = [];
    #     interfaces.${cfg-ts.bridge.name}.ipv4.addresses = [
    #       {
    #         inherit (cfg-ts.bridge) address prefixLength;
    #       }
    #     ];
    #     firewall.interfaces.${cfg-ts.network_device} = {
    #       # ports needed for dns
    #       # allowedTCPPorts = lib.optionals cfg-ts.openFirewall [53];
    #       # allowedUDPPorts = lib.optional cfg-ts.openFirewall 53;
    #     };
    #     # firewall.extraCommands = ''
    #     nat.extraCommands = ''
    #       # Forward DNS traffic from ${cfg-ts.network_device}
    #       iptables -t nat -A PREROUTING -i ${cfg-ts.network_device} -p tcp --dport 53 -j DNAT --to-destination ${containerIp}:53
    #       iptables -t nat -A PREROUTING -i ${cfg-ts.network_device} -p udp --dport 53 -j DNAT --to-destination ${containerIp}:53
    #
    #       # Enable loopback forwarding for DNS traffic from eno1
    #       iptables -t nat -A OUTPUT -o ${cfg-ts.network_device} -p tcp --dport 53 -j DNAT --to-destination ${containerIp}:53
    #       iptables -t nat -A OUTPUT -o ${cfg-ts.network_device} -p udp --dport 53 -j DNAT --to-destination ${containerIp}:53
    #
    #       # Allow incoming DNS traffic on the loopback interface
    #       iptables -A INPUT -i lo -p tcp --dport 53 -j ACCEPT
    #       iptables -A INPUT -i lo -p udp --dport 53 -j ACCEPT
    #
    #       # Enable forwarding for the redirected traffic
    #       iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
    #       iptables -A FORWARD -p tcp -d ${containerIp} --dport 53 -j ACCEPT
    #       iptables -A FORWARD -p udp -d ${containerIp} --dport 53 -j ACCEPT
    #     '';
    #   };
    #
    #   # create the nginx virtual host and security certificates
    #   services.nginx.virtualHosts.${cfg-ts.nginx.domain.name} = {
    #     useACMEHost = "eyen.ca";
    #     forceSSL = true;
    #     locations."/" = {
    #       proxyPass = "http://${containerIp}:3000";
    #     };
    #   };
    #
    #   # setup the adguard networking
    #   # networking.nat.forwardPorts = [
    #   # {proto = "tcp";
    #
    #   # create the adguard container
    #
    #   containers.adguard-ts = {
    #     inherit (inputs) nixpkgs;
    #     autoStart = true;
    #     extraFlags = ["-U"]; # for unprivileged
    #     # ephemeral = true; # don't keep track of files modified
    #     privateNetwork = true;
    #     hostBridge = cfg-ts.bridge.name;
    #     # forward ports for the dns
    #     forwardPorts = [
    #       # {
    #       #   containerPort = 53;
    #       #   hostPort = 53;
    #       #   protocol = "tcp";
    #       # }
    #       # {
    #       #   containerPort = 53;
    #       #   hostPort = 53;
    #       #   protocol = "udp";
    #       # }
    #     ];
    #
    #     config = {
    #       nixpkgs = {inherit pkgs;};
    #       system.stateVersion = "23.05";
    #       networking = {
    #         interfaces.eth0.ipv4.addresses = [
    #           {
    #             # Configure a prefix address.
    #             address = containerIp;
    #             inherit (cfg-ts.bridge) prefixLength;
    #           }
    #         ];
    #         defaultGateway = {
    #           inherit (cfg-ts.bridge) address;
    #           interface = "eth0";
    #           metric = 0;
    #         };
    #       };
    #       networking.firewall = {
    #         # ports needed for dns and gui
    #         allowedTCPPorts = [53 3000];
    #         allowedUDPPorts = [53];
    #       };
    #
    #       services.adguardhome = {
    #         enable = true;
    #         openFirewall = true;
    #         #   #         settings = adguard_settings;
    #       };
    #     };
    #   };
    # })
  ];
  #   # config = mkif cfg-home.enable {
  #   #   containers.adguard-home = {
  #   #     autostart = true;
  #   #     ephemeral = false;
  #   #
  #   #     macvlans = ["eno1"];
  #   #     bindmounts.tailscale = {
  #   #       mountpoint = "/run/secrets/tailscale_auth";
  #   #       hostpath = "/run/secrets/tailscale_auth";
  #   #       isreadonly = true;
  #   #     };
  #   #
  #   #     config = {
  #   #       config,
  #   #       pkgs,
  #   #       ...
  #   #     }: {
  #   #       services.adguardhome = {
  #   #         enable = true;
  #   #         settings = adguard_settings;
  #   #       };
  #   #
  #   #       services.tailscale = {
  #   #         enable = true;
  #   #         authkeyfile = "/run/secrets/tailscale_auth";
  #   #         extraupflags = ["--login-server" "https://hs.eyen.ca"];
  #   #       };
  #   #
  #   #       networking.firewall.allowedtcpports = [53 80 443 3000];
  #   #       networking.firewall.allowedudpports = [53];
  #   #
  #   #       networking.usedhcp = lib.mkforce true;
  #   #       networking.nameservers = ["1.1.1.1"];
  #   #       # networking.interfaces.eno1.usedhcp = true;
  #   #
  #   #       system.stateversion = "23.05";
  #   #     };
  #   #   };
  #   # };
  #   # imports = [microvm.host];
  #   config = mkIf cfg-home.enable {
  #     networking.useNetworkd = true; # https://astro.github.io/microvm.nix/simple-network.html#a-simple-network-setup
  #     # microvm.hypervisor = "cloud-hypervisor";
  #     microvm.vms = {
  #       adguard-home = {
  #         inherit pkgs;
  #         specialArgs = {inherit inputs;};
  #         config = {
  #           # It is highly recommended to share the host's nix-store
  #           # with the VMs to prevent building huge images.
  #           # 321 MB with qemu
  #           # 254 MB with cloud-hypervisor
  #           microvm.hypervisor = "cloud-hypervisor";
  #           microvm.interfaces = [
  #             {
  #               type = "tap";
  #               id = "vm-adguard-home";
  #               mac = "64:16:7F:45:BA:59";
  #             }
  #           ];
  #           imports = [../systems/defaults.nix];
  #
  #           microvm.shares = [
  #             {
  #               source = "/run/secrets/tailscale";
  #               mountPoint = "/run/secrets/tailscale";
  #               tag = "ro-tailscale-secret";
  #               proto = "virtiofs";
  #             }
  #             {
  #               source = "/nix/store";
  #               mountPoint = "/nix/.ro-store";
  #               tag = "ro-store";
  #               proto = "virtiofs";
  #             }
  #           ];
  #           services.adguardhome = {
  #             enable = true;
  #             settings = adguard_settings;
  #           };
  #
  #           services.tailscale = {
  #             enable = true;
  #             authKeyFile = "/run/secrets/tailscale/auth";
  #             extraUpFlags = ["--login-server" "https://hs.eyen.ca"];
  #           };
  #
  #           services.openssh.enable = true;
  #           networking.firewall.allowedTCPPorts = [22 53 80 443 3000];
  #           networking.firewall.allowedUDPPorts = [53];
  #
  #           networking.useDHCP = lib.mkForce true;
  #           # networking.nameservers = ["1.1.1.1"];
  #           # networking.interfaces.eno1.useDHCP = true;
  #
  #           system.stateVersion = "23.05";
  #         };
  #       };
  #     };
  #   };
  # }
}
