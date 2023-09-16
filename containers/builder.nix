{
  inputs,
  pkgs,
  unstable,
  lib,
  config,
  ...
}: let
  inherit (lib) mkOption types;
  net = (import ../common/net.nix {inherit lib;}).lib.net;
  cfg = config.container.builder;
  containerIp = net.ip.add 1 cfg.bridge.address;
in {
  options.container.builder = {
    bridge = {
      name = mkOption {
        type = types.str;
        default = "br-builder";
      };
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
          address = cfg.bridge.address;
          prefixLength = cfg.bridge.prefixLength;
        }
      ];
    };

    # create the builder container
    containers.builder = {
      autoStart = true;
      extraFlags = ["-U"]; # for unprivileged
      #ephemeral = true; # don't keep track of files modified
      ephemeral = false; # don't keep track of files modified
      privateNetwork = true;
      hostBridge = cfg.bridge.name;
      config = let
        #nix-server-secret = config.containers.builder.config.sops.secrets."nix-serve.private".path;
        #    exec nix copy --to "s3://nix-cache?region=mini-nix&endpoint=minio-api.eyen.ca&profile=hercules&parallel-compression=true&secret-key=${nix-server-secret}" $OUT_PATHS
        upload-cache-script =
          pkgs.writeShellScript "upload-cache-script.sh"
          ''
            set -eu
            set -f # disable globbing
            export IFS=' '

            echo "Uploading paths" $OUT_PATHS
          '';
      in {
        system.stateVersion = "23.05";
        environment.systemPackages = with unstable; [
          nix-build-uncached
          git
        ];
        imports = [
          inputs.sops-nix.nixosModules.sops
          #../modules/tailscale.nix
        ];
        sops = {
          # This is the actual specification of the secrets.
          secrets."nix-serve.private" = {
            mode = "0400";
            sopsFile = ../secrets/nix-serve.yaml;
          };
        };

        nix = {
          # This will add each flake input as a registry
          # To make nix3 commands consistent with your flake
          registry = lib.mapAttrs (_: value: {flake = value;}) inputs;

          # This will additionally add your inputs to the system's legacy channels
          # Making legacy nix commands consistent as well, awesome!
          nixPath = lib.mapAttrsToList (key: value: "${key}=${value.to.path}") config.nix.registry;

          settings = {
            # Enable flakes and new 'nix' command
            experimental-features = "nix-command flakes";
            # Deduplicate and optimize nix store
            auto-optimise-store = true;
            substituters = [
              "s3://nix-cache?region=mini-nix&scheme=https&endpoint=minio-api.eyen.ca"
              "https://nix-community.cachix.org"
              "https://cache.nixos.org/"
            ];
            trusted-public-keys = [
              "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            ];
            post-build-hook = [
              "${upload-cache-script}"
            ];

            max-jobs = 8;
            cores = 2;
          };
        };

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
      };
    };
  };
}
