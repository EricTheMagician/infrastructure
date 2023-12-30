# loads all available modules with `my` options available
# this is specfic to nixos. excludes home-manager options
{
  imports = [
    ./borg.nix
    ./wayland.nix
  ];
}
