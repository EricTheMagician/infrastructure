{config, ...}: let
  network_name = "home";
in {
  imports = [../../modules/nebula.nix];

  sops.secrets."nebula/racknerd.key" = {
    sopsFile = ../../secrets/headscale/nebula.yaml;
    owner = "nebula-${network_name}";
    mode = "0400";
  };
  sops.secrets."nebula/racknerd.crt" = {
    sopsFile = ../../secrets/headscale/nebula.yaml;
    owner = "nebula-${network_name}";
    mode = "0400";
  };
  services.nebula.networks.${network_name} = {
    enable = true;
    isLighthouse = true;
    isRelay = true;
    key = config.sops.secrets."nebula/racknerd.key".path;
    cert = config.sops.secrets."nebula/racknerd.crt".path;
  };
}
