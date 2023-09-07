{
  inputs,
  unstable,
  pkgs,
  config,
  ...
}: {
  disabledModules = ["services/continuous-integration/hercules-ci-agent/common.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/continuous-integration/hercules-ci-agent/common.nix")];

  sops = {
    # This is the actual specification of the secrets.
    secrets."binary-caches.json" = {
      mode = "0400";
      sopsFile = ../secrets/nix-serve.yaml;
      restartUnits = ["nix-serve.service" "hercules-ci-agent.service"];
    };
    secrets."cluster-join-token.key" = {
      mode = "0400";
      sopsFile = ../secrets/hercules.yaml;
      restartUnits = ["hercules-ci-agent.service"];
    };
  };

  services.hercules-ci-agent = {
    enable = true;
    settings = {
      binaryCachesPath = config.sops.secrets."binary-caches.json".path;
      clusterJoinTokenPath = config.sops.secrets."cluster-join-token.key".path;
    };
  };
}
