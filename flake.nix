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

    #nixos-seaweedfs.url = "github:xanderio/nixos-seaweedfs";
    #nixos-seaweedfs.url = "/home/eric/git/nixos-seaweedfs";
    #nixos-seaweedfs.inputs.nixpkgs.follows = "nixpkgs-unstable";
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

    # add my personal cache
    nixConfig = {
      extra-substituters = [
        "s3://nix-cache?region=mini-nix&profile=hercules-ci&scheme=https&endpoint=minio-api.eyen.ca"
      ];
      extra-trusted-public-keys = [
        "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
      ];
    };

    overlays = import ./overlays.nix {inherit inputs;};

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
          #nixos-seaweedfs.nixosModules.seaweedfs
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
    };

    # This is highly advised, and will prevent many possible mistakes
    checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;
    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [unstable.deploy-rs unstable.sops unstable.ssh-to-age];
    };
  };
}
