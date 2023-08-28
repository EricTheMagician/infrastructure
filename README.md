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
sh <(curl -L https://nixos.org/nix/install) --daemon
```
