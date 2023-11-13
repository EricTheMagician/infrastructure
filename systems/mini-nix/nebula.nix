{config, ...}: let
  network_name = "home";
in {
  imports = [../../modules/nebula.nix];

  sops.secrets."nebula/mini-nix.key" = {
    sopsFile = ../../secrets/mini-nix/nebula.yaml;
    owner = "nebula-${network_name}";
    mode = "0400";
  };
  sops.secrets."nebula/mini-nix.crt" = {
    sopsFile = ../../secrets/mini-nix/nebula.yaml;
    owner = "nebula-${network_name}";
    mode = "0400";
  };

  sops.secrets."nebula/certificate-authority/ca.key" = {
    sopsFile = ../../secrets/mini-nix/nebula.yaml;
    owner = config.users.users.eric.name;
    path = "${config.users.users.eric.home}/nebula/ca/ca.key";
    mode = "0400";
  };

  sops.secrets."nebula/certificate-authority/ca.crt" = {
    sopsFile = ../../secrets/mini-nix/nebula.yaml;
    owner = config.users.users.eric.name;
    path = "${config.users.users.eric.home}/nebula/ca/ca.crt";
    mode = "0400";
  };

  services.nebula.networks.${network_name} = {
    enable = true;
    key = config.sops.secrets."nebula/mini-nix.key".path;
    cert = config.sops.secrets."nebula/mini-nix.crt".path;
    settings = {
      relay = {
        use_relays = true;
      };
      punchy = {
        punch = true;
        respond = true;
      };
    };
    firewall.inbound = [
      {
        proto = "tcp";
        port = 80;
        groups = ["admin" "web-admin" "web"];
      }
      {
        proto = "tcp";
        port = 443;
        groups = ["admin" "web-admin" "web"];
      }
    ];
  };
}
