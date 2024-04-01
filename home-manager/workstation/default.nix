{
  config,
  pkgs,
  ...
}: {
  imports = [../default-desktop];
  home.packages = with pkgs; [
    # # Adds the 'hello' command to your environment. It prints a friendly
    # # "Hello, world!" when run.
    # pkgs.hello

    # # It is sometimes useful to fine-tune packages, for example, by applying
    # # overrides. You can do that directly here, just don't forget the
    # # parentheses. Maybe you want to install Nerd Fonts with a limited number of
    # # fonts?
    # (pkgs.nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })

    # # You can also create simple shell scripts directly inside your
    # # configuration. For example, this adds a command 'my-hello' to your
    # # environment:
    # (pkgs.writeShellScriptBin "my-hello" ''
    #   echo "Hello, ${config.home.username}!"
    # '')
    (vivaldi.override {proprietaryCodecs = true;})
    vivaldi-ffmpeg-codecs
    #(neovim-qt.override {neovim = config.programs.neovim.finalPackage;})
    nextcloud-client
    element-desktop
    wpsoffice
  ];

  home.shellAliases = {
    # ca = ''eval "$(micromamba shell hook --shell=bash)" && micromamba activate --stack $ORSROOT/dragonfly_python_environment_linux'';
    nqt = "nvim-qt";
  };

  services.syncthing = {
    enable = true;
    tray.enable = false;
  };

  programs = {
    # dconf.enable = true;
    vscode = {
      enable = true;
      package = pkgs.vscode.fhs;
    };
  };
  my.gdb.enable = true;
  my.gdb.pretty-print.qt.enable = true;
  my.programs.neovim.languages = {
    nix.enable = true;
    cpp.enable = true;
    python.enable = true;
  };
  my.programs.neovim.features = {
    codeium = {
      enable = true;
      enterprise = true;
    };
    perforce.enable = true;
  };
}
