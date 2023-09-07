{
  inputs,
  unstable,
  pkgs,
  config,
  ...
}: {
  disabledModules = ["services/continuous-integration/hercules-ci-agent/common.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/continuous-integration/hercules-ci-agent/common.nix")];

  services.hercules-ci-agent = {
    enable = true;
  };
}
