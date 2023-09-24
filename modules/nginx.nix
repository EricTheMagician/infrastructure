{
  config,
  lib,
  ...
}: {
  imports = [
    ./acme.nix
  ];
  options.nginx.enable = lib.mkOption {
    type = lib.types.bool;
    default = true;
  };
  config = lib.mkIf config.nginx.enable {
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
