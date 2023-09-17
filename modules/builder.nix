{
  pkgs,
  unstable,
  inputs,
  config,
  ...
}: let
  nix-server-secret = config.sops.secrets."nix-serve.private".path;
  upload-cache-script =
    pkgs.writeShellScriptBin "build-and-upload-to-cache.sh"
    ''
      set -eu
      set -f # disable globbing
      export IFS=' '
      if [[ "$1" == "" ]]; then
        echo "Missing path to build file"
        exit 1
      fi
      nix build -f "$1" --json  --no-link | ${pkgs.jq}/bin/jq '.[].outputs.out' | xargs nix copy --to "s3://nix-cache?region=mini-nix&want-mass-query=true&compression=xz&endpoint=minio-api.eyen.ca&profile=hercules&parallel-compression=true&secret-key=${nix-server-secret}"
    '';
in {
  environment.systemPackages = [upload-cache-script];
  sops = {
    # This is the actual specification of the secrets.
    secrets."nix-serve.private" = {
      mode = "0400";
      sopsFile = ../secrets/nix-serve.yaml;
    };
    secrets.aws_credentials = {
      #path = "/var/lib/users.users.hercules-ci-agent.home}/.aws/credentials";
      path = "/root/.aws/credentials";
      sopsFile = ../secrets/hercules.yaml;
    };
  };
}
