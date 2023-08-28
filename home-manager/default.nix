{
  inputs,
  unstable,
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
  home.packages = with unstable; [
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
    ripgrep
  ];

  programs = {
    bash.enable = true;
    direnv.enable = true;
    fish.enable = true;
    gitui.enable = true;
    # Let Home Manager install and manage itself.
    home-manager.enable = true;
    # enable ripgrep
    # ripgrep.enable = true; # rg command
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "headscale" = {
        host = "100.64.0.1";
        user = "root";
      };

      "vscode-server-unraid" = {
        hostname = "100.64.0.11";
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

      "vm-server2-mattermost" = {
        hostname = "10.99.99.6";
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

      " This is config for coc to enable tab completion and using enter to select
      " Use tab for trigger completion with characters ahead and navigate
      " NOTE: There's always complete item selected by default, you may want to enable
      " no select by `"suggest.noselect": true` in your configuration file
      " NOTE: Use command ':verbose imap <tab>' to make sure tab is not mapped by
      " other plugin before putting this into your config
      " inoremap <silent><expr> <TAB>
      "      \ coc#pum#visible() ? coc#pum#next(1) :
      "      \ CheckBackspace() ? "\<Tab>" :
      "      \ coc#refresh()
      inoremap <expr><S-TAB> coc#pum#visible() ? coc#pum#prev(1) : "\<C-h>"

      " Make <CR> to accept selected completion item or notify coc.nvim to format
      " <C-g>u breaks current undo, please make your own choice
      inoremap <silent><expr> <CR> coc#pum#visible() ? coc#pum#confirm()
                                    \: "\<C-g>u\<CR>\<c-r>=coc#on_enter()\<CR>"

    '';
    #extraLuaConfig = ''
    #vim.o.foldcolumn = '1' -- '0' is not bad
    #vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
    #vim.o.foldlevelstart = 99
    #vim.o.foldenable = true

    #-- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
    #vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
    #vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)

    #-- Option 1: coc.nvim as LSP client
    #require('ufo').setup()
    #'';

    plugins = with unstable.vimPlugins; [
      vim-surround
      vim-gitgutter
      nerdtree
      nerdtree-git-plugin
      fzfWrapper
      #vim-commentary
      vim-airline
      nerdcommenter
      #nvim-ufo
      coc-pyright
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

    # # You can also set the file content immediately.
    # ".gradle/gradle.properties".text = ''
    #   org.gradle.console=verbose
    #   org.gradle.daemon.idletimeout=3600000
    # '';
  };
  # You can also manage environment variables but you will have to manually
  # source
  #
  #  ~/.nix-profile/etc/profile.d/hm-session-vars.sh
  #
  # or
  #
  #  /etc/profiles/per-user/eric/etc/profile.d/hm-session-vars.sh
  #
  # if you don't want to manage your shell through Home Manager.
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
