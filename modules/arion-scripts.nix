{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.virtualisation.arion) projects;
  cfg = config.virtualisation.arion;
in {
  environment.systemPackages =
    lib.attrsets.mapAttrsToList (name: value: (pkgs.writeShellScriptBin "arion-${name}" ''
      ${cfg.package}/bin/arion --prebuilt-file "${value.settings.out.dockerComposeYaml}" $*
    ''))
    projects;
}
