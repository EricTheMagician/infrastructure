{
  config,
  inputs,
  lib,
  sops,
  ...
}
: let
  net = (import ../common/net.nix {inherit lib;}).lib.net;
  inherit (lib) mkOption types;
  cfg = config.container.kanidm;
  containerIp = net.ip.add 1 cfg.bridge.address;
in {
  options.container.kanidm = {
    bridge = {
      name = mkOption {type = types.str;};
      address = mkOption {
        type = types.str;
      };
      prefixLength = mkOption {type = types.int;};
    };
    nginx.domain.name = mkOption {
      type = types.str;
    };
  };

  config = {
    # create the network bridge from the host to the container
    networking = {
      bridges.${cfg.bridge.name}.interfaces = [];
      interfaces.${cfg.bridge.name}.ipv4.addresses = [
        {
          address = cfg.bridge.address;
          prefixLength = cfg.bridge.prefixLength;
        }
      ];
      firewall = {
        # ports needed for kanidm
        # 443 is for the webui and 636 is for the ldaps binding
        allowedTCPPorts = [443 636];
      };
    };

    # create the nginx virtual host and security certificates
    security.acme.certs.${cfg.nginx.domain.name} = {};
    services.nginx.virtualHosts.${cfg.nginx.domain.name} = {
      useACMEHost = cfg.nginx.domain.name;
      #listen = [
      #  {
      #    addr = "0.0.0.0";
      #    port = 443;
      #  }
      #];
      forceSSL = true;
      locations."/" = {
        proxyPass = "https://${containerIp}";
        extraConfig = ''
          #proxy_ssl_server_name on;
          proxy_ssl_verify_depth 2;
          proxy_ssl_name $host;
          proxy_ssl_server_name on;
          proxy_ssl_protocols  TLSv1 TLSv1.1 TLSv1.2;
          proxy_ssl_session_reuse off;
        '';
      };
    };

    # create the kanidm container

    containers.kanidm = {
      autoStart = true;
      # extraFlags = ["-U"]; # for unprivileged
      privateNetwork = true;
      hostBridge = cfg.bridge.name;
      # forward ports for the dns
      forwardPorts = [
        {
          containerPort = 443;
          hostPort = 443;
          protocol = "tcp";
        }
        {
          containerPort = 636;
          hostPort = 636;
          protocol = "tcp";
        }
      ];
      config = {config, ...}: {
        disabledModules = ["services/security/kanidm.nix"];
        imports = [
          (inputs.sops-nix.nixosModules.sops)
          (inputs.nixpkgs-unstable + "/nixos/modules/services/security/kanidm.nix")
          ../modules/acme.nix
        ];

        security.acme.certs.${cfg.nginx.domain.name} = {};
        system.stateVersion = "23.05";
        networking = {
          interfaces.eth0.ipv4.addresses = [
            {
              # Configure a prefix address.
              address = containerIp;
              prefixLength = cfg.bridge.prefixLength;
            }
          ];
          defaultGateway.address = cfg.bridge.address;
          defaultGateway.interface = "eth0";
          defaultGateway.metric = 0;
        };
        networking.firewall = {
          # ports needed for ssh and ldaps
          allowedTCPPorts = [443 636];
        };

        services.kanidm = {
          enableServer = true;
          serverSettings = {
            origin = "https://login.eyen.ca/*";
            domain = "eyen.ca";
            ldapbindaddress = "0.0.0.0:636";
            bindaddress = "0.0.0.0:443";
            tls_chain = "${config.security.acme.certs.${cfg.nginx.domain.name}.directory}/fullchain.pem";
            tls_key = "${config.security.acme.certs.${cfg.nginx.domain.name}.directory}/key.pem";
          };
        };
      };
    };
  };
}
