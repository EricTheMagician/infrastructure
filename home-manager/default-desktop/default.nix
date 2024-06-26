# this config file will list list a default set of packages that should be available on all of my desktops
{pkgs, ...}: {
  imports = [../default];
  home.packages = [
    pkgs.obsidian
    pkgs.wezterm
    pkgs.alacritty
    pkgs.element-desktop
    pkgs.ulauncher
  ];

  my.programs.neovim = {
    enable = true;
    languages = {
      nix.enable = true;
    };
    features.codeium.enable = true;
  };

  programs.vscode = {
    enable = true;
    package = pkgs.vscode.fhsWithPackages (ps: with ps; [nix-direnv]);
  };

  systemd.user.services.ulauncher = {
    # mostly taken from https://github.com/Ulauncher/Ulauncher/blob/v6/ulauncher.service
    # and https://github.com/nazarewk-iac/nix-configs/blob/a6c5949029967c1a2ae519a8de882221dfbcabce/modules/programs/ulauncher/hm.nix
    Service = {
      BusName = "io.ulauncher.Ulauncher";
      Type = "dbus";
      Restart = "on-failure";
      RestartSec = 3;
      # for v6?
      #ExecStart = "${pkgs.ulauncher}/bin/ulauncher --no-window";
      ExecStart = "${pkgs.coreutils}/bin/env GDK_BACKEND=x11 ${pkgs.ulauncher}/bin/ulauncher --hide-window";
    };
    Install = {
      WantedBy = ["graphical-session.target"];
    };
    Unit = {
      Description = "Ulauncher service";
      Documentation = "https://ulauncher.io/";
      After = ["graphical-session.target"];
      #Requires = ["tray.target"];
    };
  };
}
