{
  inputs,
  unstable,
  pkgs,
  config,
  ...
}: let
  inherit (pkgs.lib) optionalAttrs;
in {
  disabledModules = ["services/continuous-integration/hercules-ci-agent/common.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/continuous-integration/hercules-ci-agent/common.nix")];

  sops = {
    # This is the actual specification of the secrets.
    #secrets."binary-caches.json" = optionalAttrs config.services.hercules-ci-agent.enable {
    #  mode = "0400";
    #  owner = "hercules-ci-agent";
    #  group = "hercules-ci-agent";
    #  sopsFile = ../secrets/hercules.yaml;
    #  restartUnits = ["nix-serve.service" "hercules-ci-agent.service"];
    #};
    #secrets."cluster-join-token.key" = optionalAttrs config.services.hercules-ci-agent.enable {
    #  mode = "0400";
    #  owner = "hercules-ci-agent";
    #  group = "hercules-ci-agent";
    #  sopsFile = ../secrets/hercules.yaml;
    #  restartUnits = ["hercules-ci-agent.service"];
    #};
    secrets.aws_credentials = {
      #path = "/var/lib/users.users.hercules-ci-agent.home}/.aws/credentials";
      path = "/root/.aws/credentials";
      sopsFile = ../secrets/hercules.yaml;
      restartUnits = ["hercules-ci-agent.service"];
    };
  };

  services.hercules-ci-agent = {
    enable = false;
    settings = {
      binaryCachesPath = config.sops.secrets."binary-caches.json".path;
      clusterJoinTokenPath = config.sops.secrets."cluster-join-token.key".path;
    };
  };
}
