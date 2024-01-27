{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkIf;
in {
  imports = [./sops.nix];
  options.my.nextdns.api_secrets = {
    enable = mkOption {
      descrtipion = "if enabled, copies the next dns secrets needed for the nextdns api scripts";
      type = types.bool;
    };
  };
  config = mkIf config.my.nextdns.api_secrets.enable {
    sops.secrets."nextdns/api_token" = {
      sopsFile = ../secrets/nextdns.yaml;
    };
    sops.secrets."nextdns/profile/home" = {
      sopsFile = ../secrets/nextdns.yaml;
    };
    sops.secrets."nextdns/profile/tailscale" = {
      sopsFile = ../secrets/nextdns.yaml;
    };
  };
}
