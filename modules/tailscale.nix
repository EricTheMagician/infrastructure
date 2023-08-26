{ config, pkgs, inputs, tailscale_auth_path, ... }:
{
  disabledModules = [ "services/networking/tailscale.nix" ];
  imports = [ (inputs.nixpkgs-unstable + "/nixos/modules/services/networking/tailscale.nix") ];
  services.tailscale = {
    enable = true;
    authKeyFile = "/run/secrets/tailscale_auth";
    extraUpFlags = [ "--login-server" "https://hs.eyen.ca" ];
  };
  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  # make the sshd server wait for tailscale.
  systemd.services.sshd = {
    serviceConfig = {
      ExecStartPre = [
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
      sopsFile = tailscale_auth_path;
    };

  };

}
