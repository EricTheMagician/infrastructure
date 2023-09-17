# Deploying machines

To deploy all machines run:
```bash
nix run github:serokell/deploy-rs
```

To deploy a single machine
```bash
nix run github:serokell/deploy-rs .#mini-nix
```

To build and deploy locally
```bash
nixos-rebuild switch --flake .#
```

To install nix locally
```bash
curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | sh -s -- install
```

To just install my home-manager.
This assumes your username is `eric`
```bash
#build the package
nix build github:EricTheMagician/infrastructure#homeConfigurations.eric.activationPackage
# and activate
./result/activate
```

