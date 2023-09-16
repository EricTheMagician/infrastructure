{
  inputs,
  config,
  unstable,
  pkgs,
  ...
}: let
  nix-cache-domain = "nix-cache.eyen.ca";
  nix-server-secret = config.sops.secrets."nix-serve.private".path;
  upload-cache-script =
    pkgs.writeShellScript "upload-cache-script.sh"
    ''
      set -eu
      set -f # disable globbing
      export IFS=' '

      echo "Uploading paths" $OUT_PATHS
      exec nix copy --to "s3://nix-cache?region=mini-nix&endpoint=minio-api.eyen.ca&profile=hercules&parallel-compression=true&secret-key=${nix-server-secret}" $OUT_PATHS
    '';
in {
  sops = {
    # This is the actual specification of the secrets.
    secrets."nix-serve.private" = {
      mode = "0400";
      sopsFile = ../secrets/nix-serve.yaml;
      restartUnits = ["nix-serve.service"];
    };
  };

  services.nginx.clientMaxBodySize = "2048m";

  services.nix-serve = {
    enable = true;
    secretKeyFile = config.sops.secrets."nix-serve.private".path;
  };

  #nix.settings.post-build-hook = [
  #"${upload-cache-script}"
  #];

  services.nginx.virtualHosts.${nix-cache-domain} = {
    useACMEHost = "eyen.ca";
    forceSSL = true;
    locations."/" = {
      proxyPass = "http://${config.services.nix-serve.bindAddress}:${toString config.services.nix-serve.port}";
    };
  };
}
