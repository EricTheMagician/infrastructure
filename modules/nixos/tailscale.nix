{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.my.tailscale;
  inherit (lib) mkIf mkEnableOption types mkOption;
in {
  # disabledModules = ["services/networking/tailscale.nix"];
  #imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/networking/tailscale.nix")];
  options.my.tailscale = {
    enable = mkEnableOption "My Tailscale";
    user_name = mkOption {
      type = types.enum ["eric" "infrastructure" "headscale"];
      default = "infrastructure";
      description = "Tailscale user name";
    };
    extraUpFlags = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = ["--login-server" "https://hs.eyen.ca"];
    };
  };

  config = mkIf cfg.enable {
    services.tailscale = {
      enable = true;
      authKeyFile = "/run/secrets/tailscale/auth";
      inherit (cfg) extraUpFlags;
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
      secrets."tailscale/auth" = {
        mode = "0440";
        sopsFile = ../../secrets/tailscale + "/${cfg.user_name}.yaml";
      };
    };
  };
}
