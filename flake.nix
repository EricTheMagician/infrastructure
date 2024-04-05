{
  description = "Nix Infrastructure";
  inputs = {
    # Nixpkgs
    nixpkgs.url = "https://flakehub.com/f/NixOS/nixpkgs/*.tar.gz";
    nixpkgs-unstable.url = "github:nixos/nixpkgs/nixos-unstable";

    linkwarden.url = "github:EricTheMagician/nixpkgs/linkwarden";

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
    #arion.url = "github:hercules-ci/arion";
    arion.url = "github:ericthemagician/arion/docker-build";
    arion.inputs.nixpkgs.follows = "nixpkgs";

    # for pre-commit-hooks
    nix-pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";
    nix-pre-commit-hooks.inputs.nixpkgs.follows = "nixpkgs";

    # vim plugins
    vim-perforce.url = "github:nfvs/vim-perforce";
    vim-perforce.flake = false;

    # ipfs podcasting
    ipfs-podcasting.url = "https://flakehub.com/f/EricTheMagician/ipfs-podcasting.nix/*.tar.gz";
    #ipfs-podcasting.url = "/home/eric/git/ipfs-podcasting";
    ipfs-podcasting.inputs.nixpkgs.follows = "nixpkgs-unstable";

    # microvm = {
    #   url = "github:astro/microvm.nix";
    #   inputs = {nixpkgs.follows = "nixpkgs";};
    # };

    # kde 6 until it is merged into nixpkgs
    kde6.url = "github:nix-community/kde2nix";
    #kde6.inputs.nixpkgs.follows = "nixpkgs";

    # matrix/synapse deployment
    #synapse.url = "github:dali99/nixos-matrix-modules";
    libre-chat = {
      url = "github:danny-avila/LibreChat";
      flake = false;
    };

    nixvim.url = "github:nix-community/nixvim";
    nixvim.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixvim.inputs.home-manager.follows = "home-manager";
    #nixvim.inputs.home-manager.inputs.nixpkgs.follows = "nixpkgs-unstable";
    nixvim.inputs.pre-commit-hooks.follows = "nix-pre-commit-hooks";

    nvim-codeium.url = "github:Exafunction/codeium.nvim";

    # nixos-router
    nixos-router.url = "github:chayleaf/nixos-router";
    nixos-router.inputs.nixpkgs.follows = "nixpkgs";

    # notnft
    notnft.url = "github:chayleaf/notnft";
    notnft.inputs.nixpkgs.follows = "nixpkgs";
    # enable flox in my environment
    flox.url = "github:flox/flox";
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
    # microvm,
    kde6,
    libre-chat,
    nvim-codeium,
    flox,
    ...
  } @ inputs: let
    system = "x86_64-linux";
    overlays = import ./overlays.nix {inherit inputs;};
    # Unmodified nixpkgs
    pkgs = import nixpkgs {
      inherit system;
      config.allowUnfree = true;
      overlays = [
        nvim-codeium.overlays.${system}.default
        overlays.additions
        overlays.my_vim_plugins
        overlays.unstable-packages
        overlays.other-packages

        (final: prev: {
          lib = prev.lib // (import ./common/net.nix {inherit (final) lib;}).lib;
        })
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
          ./systems/defaults.nix
          ./systems/workstation/configuration.nix
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
          ipfs-podcasting.nixosModules.ipfs-podcasting
          # microvm.nixosModules.host
          ./systems/mini-nix
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
          arion.nixosModules.arion
          # microvm.nixosModules.host
          # microvm.nixosModules.microvm
          #synapse.nixosModules
          ./systems/defaults.nix
          ./systems/thepodfather/configuration.nix
        ];
      };

      nixos-rica = nixpkgs.lib.nixosSystem {
        inherit system;
        specialArgs = {
          inherit inputs;
          inherit pkgs;
        }; # Pass flake inputs to our config

        #specialArgs = {inherit pkgs;};
        modules = [
          disko.nixosModules.disko
          ./systems/defaults.nix
          ./systems/rica/configuration.nix
        ];
      };
    };

    # Standalone home-manager configuration entrypoint
    # Available through 'home-manager --flake .#your-username@your-hostname'
    homeConfigurations = {
      "eric@nixos-workstation" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs.unstable;
        extraSpecialArgs = {
          inherit inputs;
          stable = pkgs;
        }; # Pass flake inputs to our config
        #  Our main home-manager configuration file <
        modules = [
          ./home-manager/workstation
          inputs.sops-nix.homeManagerModule
          {
            home = {
              username = "eric";
              homeDirectory = "/home/eric";
            };
          }
        ];
      };

      "eric@letouch" = home-manager.lib.homeManagerConfiguration {
        pkgs = pkgs.unstable;
        extraSpecialArgs = {
          inherit inputs;
          stable = pkgs;
        }; # Pass flake inputs to our config
        #  Our main home-manager configuration file <
        modules = [
          ./home-manager/letouch
          inputs.sops-nix.homeManagerModule
          {
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
          ./home-manager/default
          inputs.sops-nix.homeManagerModule
          {
            #imports = [(inputs.sops-nix + "/modules/home-manager/sops.nix")];
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
      nixos-rica = {
        hostname = "nixos-rica";
        profiles.system = {
          fastConnection = false;
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.nixos-rica;
        };
      };
      mini-nix = {
        hostname = "mini-nix";
        profiles.system = {
          fastConnection = true;
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.mini-nix;
        };
      };

      headscale = {
        hostname = "headscale";
        profiles.system = {
          fastConnection = true;
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.headscale;
        };
      };

      thepodfather = {
        hostname = "thepodfather";
        fastConnection = true;
        profiles.system = {
          sshUser = "root";
          user = "root";
          path = deployPkgs.deploy-rs.lib.activate.nixos self.nixosConfigurations.thepodfather;
        };
      };
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

    devShells.x86_64-linux.my-admin-portal = let
      python_env = pkgs.python3.withPackages (ps: [ps.textual ps.textual ps.systemd ps.pydantic ps.typing-extensions ps.fastapi ps.uvicorn]);
    in
      pkgs.mkShell {
        nativeBuildInputs = [python_env pkgs.python3Packages.textual-dev pkgs.hatch pkgs.yarn];
        shellHook = ''
          CWD=`pwd`
          export PYTHONPATH=$CWD/src
        '';
      };
  };
}
