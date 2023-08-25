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


    # TODO: Add any other flake you might need
    # hardware.url = "github:nixos/nixos-hardware";

    # Shameless plug: looking for a way to nixify your themes and make
    # everything match nicely? Try nix-colors!
    # nix-colors.url = "github:misterio77/nix-colors";

    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = { self, nixpkgs, home-manager, disko, deploy-rs, sops-nix, nixpkgs-unstable, ... } @ inputs:
    let
      system = "x86_64-linux";
      # Unmodified nixpkgs
      pkgs = import nixpkgs { inherit system; };
      # unstable = import nixpkgs-unstable { inherit system; };
      sops = import sops-nix { inherit system; };
      sshKeys = import ./common/ssh-keys.nix;

      deployPkgs = import nixpkgs {
        inherit system;
        overlays = [
          deploy-rs.overlay
          (self: super: { deploy-rs = { inherit (pkgs) deploy-rs; lib = super.deploy-rs.lib; }; })
        ];
      };
    in
    {
      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.nixpkgs-fmt;
      # overlays = import ./overlays.nix { inherit inputs; };

      # NixOS configuration entrypoint
      # Available through 'nixos-rebuild --flake .#your-hostname'
      nixosConfigurations = {
        # FIXME replace with your hostname
        mini-nix = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; }; # Pass flake inputs to our config
          # > Our main nixos configuration file <
          modules = [
            disko.nixosModules.disko
            sops-nix.nixosModules.sops
            ./modules/sops.nix
            ./modules/nginx.nix
            ./systems/mini-nix-configuration.nix
            {
              _module.args.sshKeys = sshKeys;
            }
            ./modules/tailscale.nix
            {
              _module.args.tailscale_auth_path = ./secrets/tailscale/infrastructure.yaml;
            }
            # # adguard needs to come after configuration since it usese the hostname in the url
            ./containers/adguard.nix
          ];
        };
        headscale = nixpkgs.lib.nixosSystem {
          specialArgs = { inherit inputs; }; # Pass flake inputs to our config
          # > Our main nixos configuration file <
          modules = [
            sops-nix.nixosModules.sops
            ./systems/headscale-hardware-configuration.nix
            ./systems/headscale-configuration.nix
            ./modules/tailscale.nix
            {
              _module.args.tailscale_auth_path = ./secrets/tailscale/headscale.yaml;
              _module.args.sshKeys = sshKeys;
            }
          ];
        };
      };

      # Standalone home-manager configuration entrypoint
      # Available through 'home-manager --flake .#your-username@your-hostname'
      homeConfigurations = {
        # FIXME replace with your username@hostname
        "eric@mini-nix" = home-manager.lib.homeManagerConfiguration {
          pkgs = nixpkgs.legacyPackages.x86_64-linux; # Home-manager requires 'pkgs' instance
          extraSpecialArgs = { inherit inputs; }; # Pass flake inputs to our config
          # > Our main home-manager configuration file <
          modules = [ ./home-manager/home.nix ];
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

      # This is highly advised, and will prevent many possible mistakes
      checks = builtins.mapAttrs (system: deployLib: deployLib.deployChecks self.deploy) deploy-rs.lib;

    };
}
