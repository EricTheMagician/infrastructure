{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
in {
  #services.power-profiles-daemon.enable = lib.mkForce false;
  options.my.tlp = {
    enable = mkEnableOption "my tlp";
  };
  config = mkIf config.my.tlp.enable {
    services.tlp = {
      enable = true;
      settings = {
        START_CHARGE_THRESH_BAT0 = 75;
        STOP_CHARGE_THRESH_BAT0 = 80;
        RESTORE_THRESHOLDS_ON_BAT = 1;

        CPU_BOOST_ON_BAT = 0;
        CPU_HWP_DYN_BOOST_ON_BAT = 0;
        SCHED_POWERSAVE_ON_BAT = 1;
        NMI_WATCHDOG = 0;
        CPU_SCALING_GOVERNOR_ON_BATTERY = "powersave";
        RUNTIME_PM_ON_AC = 0;
        RUNTIME_PM_ON_BAT = "auto";
        PCIE_ASPM_ON_AC = "default";
        PCIE_ASPM_ON_BAT = "powersupersave";
        CPU_ENERGY_PERF_POLICY_ON_AC = "performance";
        CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
        CPU_MIN_PERF_ON_AC = 0;
        CPU_MAX_PERF_ON_AC = 100;
        CPU_MIN_PERF_ON_BAT = 0;
        CPU_MAX_PERF_ON_BAT = 30;
        PLATFORM_PROFILE_ON_AC = "performance";
        PLATFORM_PROFILE_ON_BAT = "low-power";
      };
    };
    environment.systemPackages = [pkgs.tlp];
  };
}
