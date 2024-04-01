{
  "headscale" = {
    host = "100.64.0.1";
    user = "root";
  };

  "mini-nix-zellij" = {
    hostname = "100.64.0.14";
    user = "eric";
    extraOptions = {
      RemoteCommand = "zellij a nix --create";
      RequestTTY = "force";
    };
  };

  "mini-nix" = {
    hostname = "100.64.0.14";
    user = "eric";
  };

  "office" = {
    hostname = "192.168.0.37";
    user = "eric";
  };

  "codeium" = {
    hostname = "192.168.0.46";
    user = "codeium";
  };

  "ftp3" = {
    hostname = "192.168.0.25";
    user = "root";
  };

  "vm-server2" = {
    hostname = "131.153.203.129";
    user = "proxmox";
    proxyJump = "192.168.0.37";
  };

  "vm-server2-proxy" = {
    hostname = "10.99.99.4";
    user = "user";
    proxyJump = "vm-server2";
  };

  "vm-server2-internal-infrastructure" = {
    hostname = "10.99.99.5";
    user = "user";
    proxyJump = "vm-server2";
  };

  "vm-server2-license-server" = {
    hostname = "10.99.99.7";
    user = "user";
    proxyJump = "vm-server2";
  };

  "vm-server2-keycloak" = {
    hostname = "10.99.99.8";
    user = "user";
    proxyJump = "vm-server2";
  };

  "vm-server2-chatbot" = {
    hostname = "10.99.99.9";
    user = "user";
    proxyJump = "vm-server2";
  };

  "vm-server2-nixos-container" = {
    hostname = "10.99.99.10";
    user = "user";
    proxyJump = "vm-server2";
  };

  "unraid" = {
    user = "root";
  };

  "thepodfather" = {
    user = "root";
  };
}
