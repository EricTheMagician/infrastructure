# this config file will list list a default set of packages that should be available on all of my desktops
{pkgs, ...}: {
  home.packages = [
    (pkgs.obsidian.override {
      electron = pkgs.electron_25.overrideAttrs (_: {
        preFixup = "patchelf --add-needed ${pkgs.libglvnd}/lib/libEGL.so.1 $out/bin/electron"; # NixOS/nixpkgs#272912
        meta.knownVulnerabilities = []; # NixOS/nixpkgs#273613
      });
    })
    pkgs.wezterm
    pkgs.element-desktop
  ];
}
