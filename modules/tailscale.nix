{
  config,
  pkgs,
  inputs,
  lib,
  ...
}: {
  disabledModules = ["services/networking/tailscale.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/networking/tailscale.nix")];
  options.tailscale = {
    secrets_path = lib.mkOption {
      type = lib.types.path;
      default = ../secrets/tailscale/infrastructure.yaml;
    };
    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["--login-server" "https://hs.eyen.ca"];
    };
  };

  config = {
    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale_auth";
      extraUpFlags = config.tailscale.extraUpFlags;
    };
    networking.firewall = {
      checkReversePath = "loose";
      trustedInterfaces = ["tailscale0"];
      allowedUDPPorts = [config.services.tailscale.port];
    };
    # make the sshd server wait for tailscale.
    systemd.services.sshd = {
      serviceConfig = {
        ExecStartPre = [
          "${pkgs.coreutils}/bin/sleep 5"
          "${pkgs.systemd}/bin/systemctl --no-block start tailscaled.service"
          "${pkgs.coreutils}/bin/sleep 5"
          "${pkgs.systemd}/bin/systemctl --no-block is-active --quiet tailscaled.service"
        ];
      };
    };

    sops = {
      # This is the actual specification of the secrets.
      secrets."tailscale_auth" = {
        mode = "0440";
        sopsFile = config.tailscale.secrets_path;
      };
    };
  };
}
