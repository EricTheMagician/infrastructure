{
  inputs,
  stable,
  config,
  pkgs,
  lib,
  ...
}: let
in {
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home.stateVersion = "23.05"; # Please read the comment before changing.

  # The home.packages option allows you to install Nix packages into your
  # environment.
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
    rclone
    # viber
    btop
    dua
    byobu
    tmux
  ];

  programs = {
    bash.enable = true;
    direnv.enable = true;
    fish.enable = true;
    gitui.enable = true;
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    fzf = {
      enable = true;
      # uses ripgrep to ignore files in my ~/.gitignore
      defaultCommand = "rg --files --hidden --ignore-file ${config.home.homeDirectory}/.gitignore";
    };
    # enable ripgrep
    ripgrep.enable = true; # rg command
  };
  programs.script-directory = {
    enable = true;
    settings = {
      SD_ROOT = "${config.home.homeDirectory}/.sd";
      SD_EDITOR = "nvim";
    };
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "headscale" = {
        host = "100.64.0.1";
        user = "root";
      };

      "vscode-server-unraid" = {
        hostname = "vscode-server-unraid";
        user = "eric";
      };

      "office" = {
        hostname = "192.168.0.37";
        user = "eric";
      };

      "codeium" = {
        hostname = "192.168.0.46";
        user = "codeium";
      };

      "ors-ftp3" = {
        hostname = "192.168.0.25";
        user = "root";
      };

      "vm-server2" = {
        hostname = "131.153.203.129";
        user = "proxmox";
        proxyJump = "192.168.0.37";
      };

      "vm-server2-proxy" = {
        hostname = "10.99.99.4";
        user = "user";
        proxyJump = "vm-server2";
      };

      "vm-server2-internal-infrastructure" = {
        hostname = "10.99.99.5";
        user = "user";
        proxyJump = "vm-server2";
      };

      "vm-server2-license-server" = {
        hostname = "10.99.99.7";
        user = "user";
        proxyJump = "vm-server2";
      };

      "vm-server2-keycloak" = {
        hostname = "10.99.99.8";
        user = "user";
        proxyJump = "vm-server2";
      };
    };
  };

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    defaultEditor = true;
    coc = {
      enable = true;
      settings = {
        coc.preferences.formatOnSaveFiletypes = ["python"];
        python = {
          formatting = {
            provider = "black";
            blackPath = "black";
          };
        };
        languageserver = {
          nix = {
            command = "rnix-lsp";
            filetypes = ["nix"];
          };
        };
      };
    };
    extraConfig = ''
      " set the maplearder to the spacebar
      " vim.g.mapleader = "<Space>"
      let mapleader = " "

      set number relativenumber
      nnoremap <C-t> :NERDTreeToggle<CR>
      nnoremap <C-p> :FZF<CR>
      " disbles mouse in neovim in general
      set mouse=

      " for nerd commentary
      filetype plugin on

    '';

    extraLuaConfig = import ./neovim-config.lua.nix;
    plugins = with pkgs.vimPlugins; [
      vim-surround
      vim-gitgutter
      vim-fugitive
      vim-surround
      coc-pyright
      coc-sh
      coc-docker
      coc-git
      coc-yaml
      coc-json
      coc-html
      coc-clangd
      coc-nginx
      coc-spell-checker
      nerdtree
      nerdtree-git-plugin
      fzfWrapper
      #vim-commentary
      vim-airline
      nerdcommenter
      nvim-ufo
      # markdown stuff
      markdown-preview-nvim
      vim-markdown-toc

      # telescope and plugins
      telescope-nvim
      telescope-vim-bookmarks-nvim
      telescope-undo-nvim
      telescope-media-files-nvim
      telescope-live-grep-args-nvim
      telescope-fzf-native-nvim
      telescope-file-browser-nvim
      telescope-coc-nvim
      neorg-telescope
    ];
  };
  #  home.file.".config/fish/config.fish".text = ''
  ## fish configuration added by home-manager
  #export MAMBA_ROOT_PREFIX=/home/eric/.config/mamba
  #if status is-interactive
  #  # Commands to run in interactive sessions can go here
  #
  #  export CONDA_EXE=$MAMBA_ROOT_PREFIX/bin/conda
  #  # This uses the type -q command to check if micromamba is in the PATH. If it is, it will run the eval command to set up the micromamba shell hook for fish. The -s fish part tells it to generate code for the fish shell.
  #  eval "$(micromamba shell hook -s fish)"
  #  alias ca "python --version"
  #end
  #'';

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".gitignore".source = ./gitignore.global;
    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };

  home.sessionVariables = {
    EDITOR = "nvim";
    WORLD = "hello";
  };

  # configure git with my defaults
  programs.git = {
    enable = true;
    userName = "Eric Yen";
    userEmail = "eric@ericyen.com";
    aliases = {prettylog = "...";};
    delta = {
      enable = true;
      options = {
        navigate = true;
        line-numbers = true;
        syntax-theme = "GitHub";
      };
    };
    extraConfig = {
      core = {editor = "nvim";};
      color = {ui = true;};
      push = {default = "simple";};
      pull = {ff = "only";};
      init = {defaultBranch = "main";};
    };
    ignores = [
      ".DS_Store"
      "*.pyc"
      "..*swp" # swap files
      "*.o"
      "result/" # for flake build
      "build/"
    ];
  };
}
