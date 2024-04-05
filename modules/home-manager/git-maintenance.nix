{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkEnableOption mkIf;
  cfg = config.my.services.git-maintenance;
in {
  options.my.services.git-maintenance = {
    enable = mkEnableOption "git maintenance";
  };
  config = mkIf cfg.enable {
    systemd.user = {
      services = let
        serviceCommand = {
          name,
          command,
        }: {
          Unit = {
            Wants = "${name}.timer";
          };
          Service = {
            Type = "oneshot";
            ExecStart = command;
            Environment = ["PATH=${pkgs.openssh}/bin:$PATH"];
          };
          Install = {
            WantedBy = ["multi-user.target"];
          };
        };
        serviceGit = {time}:
          serviceCommand {
            name = "git-${time}";
            command = "%h/.nix-profile/libexec/git-core/git --exec-path=%h/.nix-profile/libexec/git-core for-each-repo --config=maintenance.repo maintenance run --schedule=${time}";
          };
      in {
        git-hourly = serviceGit {time = "hourly";};
        git-daily = serviceGit {time = "daily";};
        git-weekly = serviceGit {time = "weekly";};
      };

      timers = let
        timer = {
          name,
          onCalendar,
        }: {
          Unit = {
            Requires = "${name}.service";
          };
          Timer = {
            OnCalendar = onCalendar;
            AccuracySec = "12h";
            Persistent = true;
          };
          Install = {
            WantedBy = ["timers.target"];
          };
        };
      in {
        git-hourly = timer {
          name = "git-hourly";
          onCalendar = "hourly";
        };
        git-daily = timer {
          name = "git-daily";
          onCalendar = "hourly";
        };
        git-weekly = timer {
          name = "git-weekly";
          onCalendar = "weekly";
        };
      };
    };
  };
}
