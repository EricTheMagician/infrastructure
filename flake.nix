{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    # Home manager
    home-manager.url = "github:nix-community/home-manager/release-23.05";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # disko disk formatter
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    hardware.url = "github:nixos/nixos-hardware";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    rnix-lsp.url = "github:nix-community/rnix-lsp";
    rnix-lsp.inputs.nixpkgs.follows = "nixpkgs";

    # for multi architecture systems
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
    deploy-rs,
    sops-nix,
    nixpkgs-unstable,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs {inherit system;};
    unstable = import nixpkgs-unstable {inherit system;};
    sops = import sops-nix {inherit system;};
    sshKeys = import ./common/ssh-keys.nix;

    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlay
        (self: super: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            lib = super.deploy-rs.lib;
          };
        })
      ];
    };
  in {
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;
    # overlays = import ./overlays.nix { inherit inputs; };

    # NixOS configuration entrypoint
    # Available through 'nixos-rebuild --flake .#your-hostname'
    nixosConfigurations = {
      mini-nix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;}; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/mini-nix-configuration.nix
          {
            _module.args.sshKeys = sshKeys;
          }
          ./modules/tailscale.nix
          {
            _module.args.tailscale_auth_path = ./secrets/tailscale/infrastructure.yaml;
          }
        ];
      };
      adguard-lxc = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          sops-nix.nixosModules.sops
          ./systems/adguard-lxc.nix
          {
            _module.args.sshKeys = sshKeys;
          }
          ./modules/tailscale.nix
          {
            _module.args.tailscale_auth_path = ./secrets/tailscale/infrastructure.yaml;
          }
        ];
      };

      headscale = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;}; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          sops-nix.nixosModules.sops
          ./systems/headscale-hardware-configuration.nix
          ./systems/headscale-configuration.nix
          {
            _module.args.sshKeys = sshKeys;
          }
          ./modules/tailscale.nix
          {
            _module.args.tailscale_auth_path = ./secrets/tailscale/headscale.yaml;
          }
        ];
      };
      vscode-infrastructure = nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs;
          inherit unstable;
        };
        modules = [
          sops-nix.nixosModules.sops
          ./systems/vscode-server-configuration.nix
          {
            _module.args.sshKeys = sshKeys;
          }
          ./modules/tailscale.nix
          {
            _module.args.tailscale_auth_path = ./secrets/tailscale/infrastructure.yaml;
          }
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      # FIXME replace with your username@hostname
      "eric" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
          inherit unstable;
        }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [
          ./home-manager
          {
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };
      "eric-desktop" = home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
          inherit unstable;
        }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [
          ./home-manager
          {
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };
    };
    # deploy-rs section
    deploy.nodes.mini-nix = {
      hostname = "192.168.88.23";
      profiles.system = {
        sshUser = "root";
        hostname = "mini-nix";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.mini-nix;
      };
    };

    deploy.nodes.adguard-lxc = {
      hostname = "100.64.0.9";
      profiles.system = {
        sshUser = "root";
        hostname = "adguard-lxc";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.adguard-lxc;
      };
    };

    deploy.nodes.headscale = {
      hostname = "100.64.0.1";
      profiles.system = {
        sshUser = "root";
        hostname = "headscale";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.headscale;
      };
    };

    deploy.nodes.vscode-infrastructure = {
      hostname = "192.168.88.32";
      profiles.system = {
        sshUser = "root";
        hostname = "vscode-server-unraid";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.vscode-infrastructure;
      };
      profiles.eric = {
        hostname = "vscode-server-unraid";
        user = "eric";
        profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
        path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations.eric.activationPackage "$PROFILE/activate";
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [unstable.deploy-rs unstable.rnix-lsp unstable.sops unstable.ssh-to-age]; # [deploy-rs rnix-lsp sops ssh-to-age];
    };
  };
}
