{
  description = "Nix Infrastructure";

  inputs = {
    # Nixpkgs
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    #mynixpkgs.url = "github:EricTheMagician/mynixpkgs";
    #mynixpkgs.inputs.nixpkgs.follows = "nixpkgs";

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

    # for pre-commit-hooks
    nix-pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    # vim plugins
    vim-perforce.url = "github:nfvs/vim-perforce";
    vim-perforce.flake = false;
    vim-codeium.url = "github:exafunction/codeium.vim";
    vim-codeium.flake = false;
    vim-spelunker.url = "github:kamykn/spelunker.vim";
    vim-spelunker.flake = false;
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    disko,
    deploy-rs,
    sops-nix,
    nixpkgs-unstable,
    nix-pre-commit-hooks,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    overlays = import ./overlays.nix {inherit inputs;};
    # Unmodified nixpkgs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [overlays.my_vim_plugins overlays.unstable-packages];
    };
    unstable = import nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
      overlays = [overlays.my_vim_plugins overlays.unstable-packages];
    };

    deployPkgs = import nixpkgs {
      inherit system;
      overlays = [
        deploy-rs.overlay
        (self: super: {
          deploy-rs = {
            inherit (pkgs) deploy-rs;
            inherit (super.deploy-rs) lib;
          };
        })
      ];
    };
  in {
    inherit overlays;
    formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

    # add my personal cache
    nixConfig = {
      extra-substituters = [
        "https://minio-api.eyen.ca/nix-cache"
      ];
      extra-trusted-public-keys = [
        "mini-nix.eyen.ca:YDI5WEPr5UGe9HjhU8y1iR07XTacpoBDQHiLcm/t2QY="
      ];
    };

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

      thepodfather = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit pkgs;
        }; # Pass flake inputs to our config

        #specialArgs = {inherit pkgs;};
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/defaults.nix
          ./systems/thepodfather/docker.machine-configuration.nix
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
          stable = pkgs;
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
    deploy.nodes = {
      mini-nix = {
        hostname = "mini-nix";
        profiles.system = {
          fastConnection = true;
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.mini-nix;
        };
        profiles.eric = {
          sshUser = "root";
          user = "eric";
          profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
          path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations.eric.activationPackage "$PROFILE/activate";
        };
      };

      adguard-lxc = {
        hostname = "100.64.0.9";
        fastConnection = true;
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.adguard-lxc;
        };
      };

      headscale = {
        hostname = "headscale";
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.headscale;
        };
      };
    };

    #deploy.nodes.nixos-workstation = {
    #  hostname = "nixos-workstation";
    #  fastConnection = true;
    #  profiles.system = {
    #    sshUser = "root";
    #    user = "root";
    #    path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-workstation;
    #  };
    #};

    deploy.nodes.thepodfather = {
      hostname = "thepodfather";
      fastConnection = true;
      profiles.system = {
        sshUser = "root";
        user = "root";
        path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.thepodfather;
      };
    };

    checks =
      # This is highly advised, and will prevent many possible mistakes
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells.x86_64-linux.default = pkgs.mkShell {
      buildInputs = [unstable.deploy-rs unstable.sops unstable.ssh-to-age unstable.nix-build-uncached unstable.statix];
      shellHook = let
        pre-commit-check = nix-pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            alejandra.enable = true;
            nil.enable = true;
            statix.enable = true;
          };
        };
      in
        pre-commit-check.shellHook;
    };
  };
}
