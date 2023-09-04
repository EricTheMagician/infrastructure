{
  description = "Your new nix config";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    mynixpkgs.url = "github:EricTheMagician/mynixpkgs";
    mynixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # disko disk formatter
    disko.url = "github:nix-community/disko";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    hardware.url = "github:nixos/nixos-hardware";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

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
    mynixpkgs,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    # Unmodified nixpkgs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
    };
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };
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
      nixos-workstation = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit unstable;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/nixos-workstation-configuration.nix
        ];
      };

      mini-nix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit unstable;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/mini-nix-configuration.nix
        ];
      };

      adguard-lxc = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {inherit inputs;};
        modules = [
          sops-nix.nixosModules.sops
          ./systems/adguard-lxc.nix
        ];
      };

      headscale = nixpkgs.lib.nixosSystem {
        specialArgs = {inherit inputs;}; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          sops-nix.nixosModules.sops
          ./systems/headscale-configuration.nix
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
      "eric@nixos-workstation" = home-manager.lib.homeManagerConfiguration {
        pkgs = unstable; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          #inherit nixpkgs;
          mypkgs = mynixpkgs.packages.${system};
          inherit inputs;
          stable = pkgs;
        }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [
          ./home-manager
          ./home-manager/eric-desktop.nix
          {
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };
      "eric" = home-manager.lib.homeManagerConfiguration {
        pkgs = unstable; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
          mypkgs = mynixpkgs.packages.${system};
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
      hostname = "mini-nix";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.mini-nix;
      };
      profiles.eric = {
        user = "eric";
        profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
        path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations.eric.activationPackage "$PROFILE/activate";
      };
    };

    deploy.nodes.adguard-lxc = {
      hostname = "100.64.0.9";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.adguard-lxc;
      };
    };

    deploy.nodes.headscale = {
      hostname = "headscale";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.headscale;
      };
    };

    deploy.nodes.nixos-workstation = {
      hostname = "nixos-workstation";
      fastConnection = true;
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-workstation;
      };
      profiles.eric = {
        sshUser = "eric";
        user = "eric";
        profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
        path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations."eric@nixos-workstation".activationPackage "$PROFILE/activate";
      };
    };

    deploy.nodes.vscode-infrastructure = {
      hostname = "vscode-server-unraid";
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.vscode-infrastructure;
      };
      profiles.eric = {
        user = "eric";
        profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
        path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations.eric.activationPackage "$PROFILE/activate";
      };
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [unstable.deploy-rs unstable.sops unstable.ssh-to-age];
    };
  };
}
