{
  # {
  #   config,
  #   pkgs,
  #   lib,
  #   inputs,
  #   ...
  # }: let
  #   inherit ((import ../common/net.nix {inherit lib;}).lib) net;
  #   inherit (lib) mkOption mkEnableOption types mkIf;
  #   adguard_settings = import ./settings/adguard.nix;
  #   cfg = config.my.container.adguard;
  #   # this is the ip we need to expose
  #   containerIp = net.ip.add 1 cfg.bridge.address;
  #   # microvm = inputs.microvm.nixosModules.microvm;
  # in {
  #   options.my.container.adguard = {
  #     enable = mkEnableOption "adguard containers";
  #     bridge = {
  #       name = mkOption {type = types.str;};
  #       address = mkOption {
  #         type = types.str;
  #       };
  #       prefixLength = mkOption {type = types.int;};
  #     };
  #     nginx.domain.name = mkOption {
  #       type = types.str;
  #     };
  #     openFirewall = mkEnableOption "if enabled, opens port 53 on all ports";
  #     network_device = mkOption {
  #       type = types.listOf types.str;
  #       default = ["eno1"];
  #     };
  #   };
  #
  #   # config = {
  #   #   # create the network bridge from the host to the container
  #   #   networking = {
  #   #     bridges.${cfg.bridge.name}.interfaces = [];
  #   #     interfaces.${cfg.bridge.name}.ipv4.addresses = [
  #   #       {
  #   #         inherit (cfg.bridge) address;
  #   #         inherit (cfg.bridge) prefixLength;
  #   #       }
  #   #     ];
  #   #     firewall = {
  #   #       # ports needed for dns
  #   #       allowedTCPPorts = lib.optional cfg.openFirewall 53;
  #   #       allowedUDPPorts = lib.optional cfg.openFirewall 53;
  #   #     };
  #   #   };
  #   #
  #   #   # create the nginx virtual host and security certificates
  #   #   services.nginx.virtualHosts.${cfg.nginx.domain.name} = {
  #   #     useACMEHost = "eyen.ca";
  #   #     forceSSL = true;
  #   #     locations."/" = {
  #   #       proxyPass = "http://${containerIp}:3000";
  #   #     };
  #   #   };
  #   #
  #   #   # create the adguard container
  #   #
  #   #   containers.adguard = {
  #   #     autoStart = true;
  #   #     extraFlags = ["-U"]; # for unprivileged
  #   #     ephemeral = true; # don't keep track of files modified
  #   #     privateNetwork = true;
  #   #     hostBridge = cfg.bridge.name;
  #   #     # forward ports for the dns
  #   #     forwardPorts = [
  #   #       {
  #   #         containerPort = 53;
  #   #         hostPort = 53;
  #   #         protocol = "tcp";
  #   #       }
  #   #       {
  #   #         containerPort = 53;
  #   #         hostPort = 53;
  #   #         protocol = "udp";
  #   #       }
  #   #     ];
  #   #     config = {
  #   #       system.stateVersion = "23.05";
  #   #       networking = {
  #   #         interfaces.eth0.ipv4.addresses = [
  #   #           {
  #   #             # Configure a prefix address.
  #   #             address = containerIp;
  #   #             inherit (cfg.bridge) prefixLength;
  #   #           }
  #   #         ];
  #   #         defaultGateway = {
  #   #           inherit (cfg.bridge) address;
  #   #           interface = "eth0";
  #   #           metric = 0;
  #   #         };
  #   #       };
  #   #       networking.firewall = {
  #   #         # ports needed for dns
  #   #         allowedTCPPorts = [53];
  #   #         allowedUDPPorts = [53];
  #   #       };
  #   #
  #   #       services.adguardhome = {
  #   #         enable = true;
  #   #         openFirewall = true;
  #   #       };
  #   #     };
  #   #   };
  #   # };
  #   # config = mkIf cfg.enable {
  #   #   containers.adguard-home = {
  #   #     autoStart = true;
  #   #     ephemeral = false;
  #   #
  #   #     macvlans = ["eno1"];
  #   #     bindMounts.tailscale = {
  #   #       mountPoint = "/run/secrets/tailscale_auth";
  #   #       hostPath = "/run/secrets/tailscale_auth";
  #   #       isReadOnly = true;
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
  #   #         authKeyFile = "/run/secrets/tailscale_auth";
  #   #         extraUpFlags = ["--login-server" "https://hs.eyen.ca"];
  #   #       };
  #   #
  #   #       networking.firewall.allowedTCPPorts = [53 80 443 3000];
  #   #       networking.firewall.allowedUDPPorts = [53];
  #   #
  #   #       networking.useDHCP = lib.mkForce true;
  #   #       networking.nameservers = ["1.1.1.1"];
  #   #       # networking.interfaces.eno1.useDHCP = true;
  #   #
  #   #       system.stateVersion = "23.05";
  #   #     };
  #   #   };
  #   # };
  #   # imports = [microvm.host];
  #   config = mkIf cfg.enable {
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
