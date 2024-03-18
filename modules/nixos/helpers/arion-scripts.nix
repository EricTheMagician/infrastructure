{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (config.virtualisation.arion) projects;
  cfg = config.virtualisation.arion;
in {
  # this module is used to create a set of executables arion project as a direct `docker-compose -f file.yaml` replacement
  # for example,  `arion-immich pull && arion-immich up -d`
  environment.systemPackages =
    lib.attrsets.mapAttrsToList (name: value: (pkgs.writeShellScriptBin "arion-${name}" ''
      ${cfg.package}/bin/arion --prebuilt-file "${value.settings.out.dockerComposeYaml}" $*
    ''))
    projects;
}
