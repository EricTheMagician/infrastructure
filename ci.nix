let
  outputs = builtins.getFlake (toString ./.);
  #pkgs = outputs.inputs.nixpkgs;
  #drvs = pkgs.lib.collect pkgs.lib.isDerivation outputs.deploy;
  systems = builtins.mapAttrs (k: v: v.config.system.build.toplevel) outputs.nixosConfigurations;
  home-manager = builtins.mapAttrs (k: v: v.activationPackage) outputs.homeConfigurations;
  #drvs = pkgs.lib.collect pkgs.lib.isDerivation outputs.nixosConfigurations;
in [
  systems
  home-manager
  outputs.devShells
]
