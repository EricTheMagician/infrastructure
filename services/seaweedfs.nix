{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.services.seaweedfs;
  inherit (lib) mkOption mkIf types mkEnableOption optional concatStringsSep;
  seaweedfs_enabled = builtins.any (x: x.enable) [cfg.master cfg.filer];
in {
  options.services.seaweedfs = {
    default = {
      package =
        mkOption
        {
          type = types.package;
          description = "seaweedfs package to use";
          default = pkgs.seaweedfs;
        };
    };
    master = {
      enable = mkEnableOption "seaweedfs master server";
      port = mkOption {
        type = types.port;
        default = 9333;
      };

      "port.grpc" = mkOption {
        type = types.nullOr types.port;
        default = null;
      };

      openFirewall = mkOption {
        type = types.bool;
        default = false;
      };
      #root_dir = mkOption {
      #  type = types.str;
      #  default = "/var/lib/seaweedfs";
      #  description = "base dir for master dir";
      #};
      #metadata_dir = mkOption {
      #  type = types.str;
      #  default = cfg.master.root_dir + "/metadata_dir";
      #};
      package =
        mkOption
        {
          type = types.nullOr types.package;
          description = "seaweedfs package to use";
          default = pkgs.seaweedfs;
        };
    };
  };

  config = {
    networking.firewall.allowedTCPPorts = optional cfg.master.openFirewall [cfg.master.port];

    systemd.services.seaweedfs-master = mkIf cfg.master.enable (let
      pkg =
        if cfg.master.package == null
        then cfg.default.package
        else cfg.master.package;

      args = concatStringsSep " " [
        "-port=${toString cfg.master.port}"
      ];
    in {
      documentation = ["https://github.com/seaweedfs/seaweedfs/wiki"];
      description = "seaweedfs server";
      wantedBy = ["multi-user.target"];
      after = ["networking.target"];
      serviceConfig = {
        DynamicUser = true;
        ExecStart = "${pkg}/bin/weed master ${args}";
        Restart = "always";
        RestartSec = 10;
        RuntimeDirectory = "seaweedfs";
        StateDirectory = "seaweedfs";
      };
    });
  };
}
