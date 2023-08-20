{ config, pkgs, ... }:
{
  services.tailscale.enable = true;
  networking.firewall = {
    checkReversePath = "loose";
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };
  # make the sshd server wait for tailscale.
  systemd.services.sshd = {
    serviceConfig = {
      ExecStartPre = [
        "${pkgs.coreutils}/bin/sleep 5"
        "${pkgs.systemd}/bin/systemctl --no-block start tailscaled.service"
        "${pkgs.systemd}/bin/systemctl --no-block is-active --quiet tailscaled.service"
      ];
    };
  };
}
