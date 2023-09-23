{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
in {
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
    vivaldi
    vivaldi-ffmpeg-codecs
    # gs.unstablevscode.fhs
    # vscode
    # (
    #   vscode-with-extensions.override
    #   {
    #     vscodeExtensions = with pkgs.vscode-extensions;
    #     [

    #       # generatl development related packages
    #       ms-vscode-remote.remote-ssh
    #       eamodio.gitlens
    #       # ms-vscode.powershell
    #       # ms-azuretools.vscode-docker

    #       # python related packages
    #       ms-python.python
    #       ms-python.vscode-pylance

    #       # C++ related packages
    #       ms-vscode.cpptools
    #       ms-vscode.cmake-tools
    #       xaver.clang-format

    #       # nix related packages
    #       bbenoist.nix
    #       arrterian.nix-env-selector
    #       jnoortheen.nix-ide
    #     ] ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace
    #     [
    #       {
    #         publisher = "mjcrouch";
    #         name = "perforce";
    #         version = "4.15.7";
    #         sha256 = "sha256-BXBfxg2GrXvohvu2b02JqtxbGxPxSanNId6DQ39akHI=";
    #       }
    #       {
    #         publisher = "ms-python";
    #         name = "black-formatter";
    #         version ="2023.5.12151008";
    #         sha256 = "sha256-YBcyyE9Z2eL914J8I97WQW8a8A4Ue6C0pCUjWRRPcr8=";
    #       }
    #       {
    #         publisher = "Codeium";
    #         name = "codeium-enterprise-updater";
    #         version = "1.0.9";
    #         sha256 = "sha256-WyDVhc9fjQ+Qgw7F04ESxicRK53vaVxgFtGRHQGpgeI=";
    #       }
    #     ];
    #   }
    # )

    (neovim-qt.override {neovim = config.programs.neovim.finalPackage;})
    obsidian
    nextcloud-client
  ];

  home.aliases = {
    ca = ''eval "$(micromamba shell hook --shell=bash)" && micromamba activate --stack $ORSROOT/dragonfly_python_environment_linux'';
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
}
