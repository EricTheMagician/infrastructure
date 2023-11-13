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
  networking.firewall.interfaces."nebula.${network_name}".allowedTCPPorts = [22 80 443];
  services.nebula.networks.${network_name} = {
    enable = true;
    isLighthouse = true;
    isRelay = true;
    key = config.sops.secrets."nebula/racknerd.key".path;
    cert = config.sops.secrets."nebula/racknerd.crt".path;
    settings = {
      punchy = {punch = true;};
      firewall = {
        outbound_action = "reject";
        inbound_action = "reject";
      };
      use_relay = true;
      #logging.level = "debug";
      sshd = {
        # useful for debugging
        enabled = false;
        listen = "127.0.0.1:2222";
        host_key = "/etc/nebula/ssh_host_ed25519_key";
        authorized_users = [
          {
            user = "root";
            keys = ["ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPty7RRl139wuxHHdcGrhnYW35iWho7UKnbHfeVk/kyw root@racknerd-08df0e"];
          }
        ];
      };
    };
    #firewall.inbound = [
    #  {
    #    proto = "tcp";
    #    port = 443;
    #    groups = ["admin" "web-all"];
    #  }
    #  {
    #    proto = "tcp";
    #    port = 80;
    #    groups = ["admin" "web-all"];
    #  }
    #];
  };
}
