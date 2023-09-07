{
  inputs,
  config,
  unstable,
  ...
}: let
  nix-cache-domain = "nix-cache.eyen.ca";
in {
  sops = {
    # This is the actual specification of the secrets.
    secrets.nix-serve.private = {
      mode = "0400";
      sopsFile = ../secrets/nix-serve.yaml;
      group = "nix-serve";
      owner = "nix-serve";
      restartUnits = ["nix-serve.service"];
    };
  };

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets.nix-serve.private.path;
    #package = unstable.nix-serve-ng;
  };

  nginx.virtualHosts.${nix-cache-domain} = {
    useACMEHost = "eyen.ca";
    locations."/" = {
      proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
    };
  };
}
