{
  description = "Nix Infrastructure";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    #mynixpkgs.url = "github:EricTheMagician/mynixpkgs";
    #mynixpkgs.inputs.nixpkgs.follows = "nixpkgs";

    # Home manager
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";
    # disko disk formatter
    disko.url = "https://flakehub.com/f/nix-community/disko/*.tar.gz";
    disko.inputs.nixpkgs.follows = "nixpkgs";

    sops-nix.url = "https://flakehub.com/f/Mic92/sops-nix/*.tar.gz";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";
    sops-nix.inputs.nixpkgs-stable.follows = "nixpkgs";

    hardware.url = "https://flakehub.com/f/NixOS/nixos-hardware/*.tar.gz";

    deploy-rs.url = "github:serokell/deploy-rs";
    deploy-rs.inputs.nixpkgs.follows = "nixpkgs";

    # arion docker-compose in nix
    arion.url = "github:hercules-ci/arion";
    arion.inputs.nixpkgs.follows = "nixpkgs";

    # for pre-commit-hooks
    nix-pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nix-pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # vim plugins
    vim-perforce.url = "github:nfvs/vim-perforce";
    vim-perforce.flake = false;
    vim-codeium.url = "github:exafunction/codeium.vim";
    vim-codeium.flake = false;
    vim-spelunker.url = "github:kamykn/spelunker.vim";
    vim-spelunker.flake = false;

    # ipfs podcasting
    ipfs-podcasting.url = "https://flakehub.com/f/EricTheMagician/ipfs-podcasting.nix/*.tar.gz";
    #ipfs-podcasting.url = "/home/eric/git/ipfs-podcasting";
    ipfs-podcasting.inputs.nixpkgs.follows = "nixpkgs-unstable";

    microvm = {
      url = "github:astro/microvm.nix";
      inputs = {nixpkgs.follows = "nixpkgs";};
    };

    # kde 6 until it is merged into nixpkgs
    kde6.url = "github:nix-community/kde2nix";
    #kde6.inputs.nixpkgs.follows = "nixpkgs";

    # matrix/synapse deployment
    #synapse.url = "github:dali99/nixos-matrix-modules";
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
    arion,
    ipfs-podcasting,
    microvm,
    kde6,
    mynixpkgs,
    #synapse,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    overlays = import ./overlays.nix {inherit inputs;};
    # Unmodified nixpkgs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        overlays.additions
        overlays.my_vim_plugins
        overlays.unstable-packages
      ];
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
          inherit pkgs;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/defaults.nix
          ./systems/nixos-workstation-configuration.nix
        ];
      };

      letouch = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit pkgs;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          sops-nix.nixosModules.sops
          ./systems/defaults.nix
          ./systems/letouch
          #kde6.nixosModules.default
          #{
          #  services.xserver.desktopManager.plasma6.enable = true;
          #  programs.ssh.askPassword = pkgs.gnome.seahorse + "/bin/seahorse";
          #}
        ];
      };

      mini-nix = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit pkgs;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ipfs-podcasting.nixosModules.ipfs-podcasting
          microvm.nixosModules.host
          ./systems/mini-nix
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
        specialArgs = {
          inherit inputs;
          inherit pkgs;
        }; # Pass flake inputs to our config
        # > Our main nixos configuration file <
        modules = [
          disko.nixosModules.disko
          sops-nix.nixosModules.sops
          ./systems/defaults.nix
          ./systems/headscale
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
          arion.nixosModules.arion
          microvm.nixosModules.host
          #synapse.nixosModules
          ./systems/defaults.nix
          ./systems/thepodfather/configuration.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "eric@nixos-workstation" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs.unstable; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
        }; # Pass flake inputs to our config
        #  Our main home-manager configuration file <
        modules = [
          ./home-manager
          ./home-manager/desktops/workstation.nix
          inputs.sops-nix.homeManagerModule
          {
            my.programs.plik.enable = true;
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };

      "eric@letouch" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs.unstable; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
        }; # Pass flake inputs to our config
        #  Our main home-manager configuration file <
        modules = [
          ./home-manager
          ./home-manager/desktops/default.nix
          inputs.sops-nix.homeManagerModule
          {
            my.programs.plik.enable = true;
            my.programs.neovim.languages = {nix.enable = true;};
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };
      "eric" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs.unstable; # Home-manager requires 'pkgs' instance
        extraSpecialArgs = {
          inherit inputs;
          stable = pkgs;
        }; # Pass flake inputs to our config
        # > Our main home-manager configuration file <
        modules = [
          ./home-manager
          inputs.sops-nix.homeManagerModule
          {
            #imports = [(inputs.sops-nix + "/modules/home-manager/sops.nix")];
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
            my.programs.plik.enable = true;
            my.programs.neovim.languages = {nix.enable = true;};
            #my.programs.neovim.codeium.nvim = true;
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
      #profiles.eric = {
      #  sshUser = "root";
      #  user = "eric";
      #  profilePath = "/nix/var/nix/profiles/per-user/eric/home-manager";
      #  path = deploy-rs.lib.${system}.activate.custom self.homeConfigurations.eric.activationPackage "$PROFILE/activate";
      #};
    };

    checks =
      # This is highly advised, and will prevent many possible mistakes
      builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    devShells.x86_64-linux.default = let
      update-dns-python-script = pkgs.callPackage ./packages/nextdns-update {};
      host-json = pkgs.writeText "host.json" (builtins.toJSON (import ./common/dns/custom_domains.nix));
      update-dns-shell-script = pkgs.writeShellScriptBin "update-nextdns" ''
        API_KEY=$(sudo cat /run/secrets/nextdns/api_token)
        HOME_PROFILE=$(sudo cat /run/secrets/nextdns/profile/home)
        TAILSCALE_PROFILE=$(sudo cat /run/secrets/nextdns/profile/tailscale)
        ${update-dns-python-script.interpreter} ${update-dns-python-script.script} \
            --json-hosts-file ${host-json} \
            --api-key $API_KEY \
            --home-profile $HOME_PROFILE \
            --tailscale-profile $TAILSCALE_PROFILE
      '';
    in
      pkgs.mkShell {
        buildInputs = [pkgs.unstable.deploy-rs pkgs.unstable.sops pkgs.unstable.ssh-to-age pkgs.unstable.nix-build-uncached pkgs.unstable.statix update-dns-shell-script];
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
