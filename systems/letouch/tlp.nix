{
  pkgs,
  lib,
  ...
}: {
  services.power-profiles-daemon.enable = lib.mkForce false;
  services.tlp = {
    enable = true;
    settings = {
      START_CHARGE_THRESH_BAT0 = 0;
      STOP_CHARGE_THRESH_BAT0 = 1;
      RESTORE_THRESHOLDS_ON_BAT = 1;

      CPU_DRIVER_OPMODE_ON_AC = "active";
      CPU_DRIVER_OPMODE_ON_BAT = "active";
      CPU_SCALING_GOVERNOR_ON_AC = "powersave";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_BOOST_ON_AC = "1";
      CPU_BOOST_ON_BAT = "0";
      CPU_HWP_DYN_BOOST_ON_BAT = "0";
      CPU_HWP_DYN_BOOST_ON_AC = "3";
      #SCHED_POWERSAVE_ON_BAT = 1;
      # kernel watchdog
      # The Linux kernel can act as a watchdog to detect both soft and hard lockups.
      NMI_WATCHDOG = 0;

      MEM_SLEEP_ON_AC = "deep";
      MEM_SLEEP_ON_BAT = "deep";
      CPU_ENERGY_PERF_POLICY_ON_AC = "power";
      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      PLATFORM_PROFILE_ON_AC = "performance";
      PLATFORM_PROFILE_ON_BAT = "low-power";
    };
  };
  environment.systemPackages = [pkgs.tlp];
}
