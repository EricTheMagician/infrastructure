{
  unstable,
  lib,
  config,
  ...
}: let
  cfg = config.container.forgejo-action-runner;
  containerIp = net.ip.add 1 cfg.bridge.address;
  forgejo_domain = "https://git.eyen.ca";
  inherit ((import ../../common/net.nix {inherit lib;}).lib) net;
  inherit (lib) mkOption types;
  secret_file = config.sops.secrets."git/runner".path;
in {
  options.container.forgejo-action-runner = {
    bridge = {
      name = mkOption {type = types.str;};
      address = mkOption {
        type = types.str;
      };
      prefixLength = mkOption {type = types.int;};
    };
  };
  config = {
    # create the network bridge from the host to the container
    networking = {
      bridges.${cfg.bridge.name}.interfaces = [];
      interfaces.${cfg.bridge.name}.ipv4.addresses = [
        {
          inherit (cfg.bridge) address;
          inherit (cfg.bridge) prefixLength;
        }
      ];
      firewall = {
        # ports needed for kanidm
        # 443 is for the webui and 636 is for the ldaps binding
        allowedTCPPorts = [443 636];
      };
    };

    sops.secrets."git/runner" = {sopsFile = ../../secrets/git.yaml;};
    containers.forgejo-action-runner = {
      autoStart = true;
      privateNetwork = true;
      hostBridge = cfg.bridge.name;
      bindMounts = {
        "sops runner secret" = {
          hostPath = secret_file;
          mountPoint = secret_file;
        };
      };
      specialArgs = {inherit unstable;};
      config = {
        config,
        unstable,
        ...
      }: {
        system.stateVersion = "23.05";
        services.gitea-actions-runner = {
          package = unstable.forgejo-actions-runner;
          instances.runner = {
            enable = true;
            labels = ["native:host"];
            name = "workstation-runner";
            tokenFile = secret_file;
            url = forgejo_domain;
          };
        };
        networking = {
          interfaces.eth0.ipv4.addresses = [
            {
              # Configure a prefix address.
              address = containerIp;
              inherit (cfg.bridge) prefixLength;
            }
          ];
          defaultGateway = {
            inherit (cfg.bridge) address;
            interface = "eth0";
            metric = 0;
          };
        };
      };
    };
  };
}
