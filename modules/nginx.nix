{
  config,
  pkgs,
  ...
}: let
in {
  imports = [
    ./acme.nix
  ];
  config = {
    services.nginx = {
      enable = true;
      recommendedProxySettings = true;
      recommendedTlsSettings = true;
    };
    users.users.nginx.extraGroups = [config.security.acme.defaults.group];
    networking.firewall = {
      # ports needed for dns
      allowedTCPPorts = [80 443];
    };
  };
}
