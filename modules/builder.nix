{
  pkgs,
  unstable,
  inputs,
  config,
  ...
}: let
  nix-server-secret = config.sops.secrets."nix-serve.private".path;
  upload-cache-script =
    pkgs.writeShellScript "upload-cache-script.sh"
    ''
      set -eu
      set -f # disable globbing
      export IFS=' '

      echo "Uploading paths" $OUT_PATHS
      exec nix copy --to "s3://nix-cache?region=mini-nix&compression=xz&endpoint=minio-api.eyen.ca&profile=hercules&parallel-compression=true&secret-key=${nix-server-secret}" $OUT_PATHS
    '';
in {
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

  nix.settings = {
    post-build-hook = [upload-cache-script];
  };
}
