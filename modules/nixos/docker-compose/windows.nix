/*
This uses the dockur/windows image to install windows in vm.
It uses KVM under the hood.
Note that this will likely require root privileges. At the very least, require being able to create a kvm vm.
*/
{
  config,
  lib,
  ...
}: let
  inherit (lib) mkOption mkIf mkEnableOption types;
  mkPortMap = port: type: range: (builtins.map (ip: "${ip}:${port}:${port}/${type}") range);
  cfg = config.my.windows;
in {
  options.my.windows = {
    enable = mkEnableOption "windows vm";
    host_ip = mkOption {
      type = types.listOf types.str;
      default = [];
    };

    data_location = mkOption {
      type = types.str;
      default = "/var/lib/windows-vm";
    };

    settings = {
      RAM_SIZE = mkOption {
        type = types.str;
        default = "8G";
      };
      CPU_CORES = mkOption {
        type = types.str;
        default = "4";
      };
      DISK_SIZE = mkOption {
        type = types.str;
        default = "64GB";
      };
    };
  };
  config = mkIf cfg.enable {
    virtualisation.arion.projects.windows.settings.services = {
      windows.service = {
        image = "dockurr/windows";
        container_name = "windows-vm";
        devices = ["/dev/kvm"];
        capabilities = {"NET_ADMIN" = true;};
        ports =
          (mkPortMap "3389" "tcp" cfg.host_ip)
          ++ (mkPortMap "3389" "udp" cfg.host_ip)
          ++ (mkPortMap "8006" "tcp" cfg.host_ip);
        stop_grace_period = "2m";
        restart = "on-failure";
        environment =
          {
            VERSION = "tiny11";
          }
          // cfg.settings;
        volumes = [
          "${cfg.data_location}:/storage"
        ];
      };
    };

    my.backups.services.windows-vm = {
      paths = [cfg.data_location];
      startAt = "weekly";
    };
  };
}
