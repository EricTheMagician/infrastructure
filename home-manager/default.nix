{
  config,
  pkgs,
  mypkgs,
  ...
}: let
  # vimspector debuggers
  python-debugpy = pkgs.python310.withPackages (ps: with ps; [debugpy]);
  debugpy_path = python-debugpy + "/lib/python3.10/site-packages/debugpy";

  codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb.overrideAttrs (finalAttrs: previousAttrs: {lldb = pkgs.lldb_16;});
  codelldb_path = "${codelldb}/share/vscode/extensions/vadimcn.vscode-lldb/${codelldb.vscodeExtPublisher}.${codelldb.vscodeExtName}";
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
    nil # nix lsp
    python310Packages.debugpy
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
    gh.enable = true;
    gh-dash.enable = true;
    # enable ripgrep
    ripgrep.enable = true; # rg command
    script-directory = {
      enable = true;
      settings = {
        SD_ROOT = "${config.home.homeDirectory}/.sd";
        SD_EDITOR = "nvim";
      };
    };

    ssh = {
      enable = true;
      matchBlocks = import ./ssh-match-blocks.nix;
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
        coc.preferences.formatOnSaveFiletypes = ["python" "nix" "json"];
        pyright.enable = true;
        python = {
          formatting = {
            provider = "black";
            blackPath = "${pkgs.black}/bin/black";
          };
          # pyright only
          analysis.autoImportCompletions = false;
        };
        pyright = {
          disableCompletion = false;
          disableDiagnostics = false;
          disableDocumentation = false;
          disableProgressNotifications = false;
          completion = {
            importSupport = true;
            snippetSupport = true;
          };
          inlayHints = {
            functionReturnTypes = true;
            variableTypes = true;
          };
        };
        languageserver = {
          pylance = {
            enabled = true;
            filetypes = ["python"];
            env = {
              ELECTRON_RUN_AS_NODE = "1";
              VSCODE_NLS_CONFIG = "1";
            };
            #module = pkgs.vscode-extensions.ms-python.vscode-pylance + "/share/vscode/extensions/MS-python.vscode-pylance/dist/server.bundle.js";
            module = mypkgs.vscode-pylance + "/share/vscode/extensions/MS-python.vscode-pylance/dist/server.bundle.js";
            initializationOptions = {};
            settings = {
              python.analysis.typeCheckingMode = "basic";
              python.analysis.diagnosticMode = "openFilesOnly";
              python.analysis.stubPath = "./typings";
              python.analysis.autoSearchPaths = true;
              python.analysis.extraPaths = [];
              python.analysis.diagnosticSeverityOverrides = {};
              python.analysis.useLibraryCodeForTypes = true;
            };
          };
          nix = {
            command = "nil";
            filetypes = ["nix"];
            rootPatterns = ["flake.nix"];
            settings.nil.formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
          };
        };
      };
    };

    extraConfig = ''
      " disbles mouse in neovim in general
      " set mouse=
      " set the maplearder to the spacebar
      " vim.g.mapleader = "<Space>"
      let mapleader = " "

      noremap  <leader>ti :tabprevious<CR>
      noremap <leader>to :tabnext<CR>
      noremap <leader>tn :tabnew<CR>
      noremap <leader>vr :ViminspectorReset<CR>
      set number relativenumber expandtab shiftwidth=4 softtabstop=4 smarttab
      nnoremap <C-t> :NERDTreeFind<CR>

      let g:vimspector_enable_mappings = 'HUMAN'
      let g:vimspector_base_dir=expand( '$HOME/.config/vimspector' )

      " open file on perforce on save
      let g:perforce_open_on_save = 1
      " saving on change is preferred, at least in neovim.
      " writing a buffer to disk is a change.
      " editing a buffer is not a change.
      let g:perforce_open_on_change = 1
      " don't prompt on every save
      let g:perforce_prompt_on_open = 0

      " Vim inspector
      " mnemonic 'di' = 'debug inspect' (pick your own, if you prefer!)
      " for normal mode - the word under the cursor
      nmap <Leader>di <Plug>VimspectorBalloonEval
      " nmap for visual mode, the visually selected text
      xmap <Leader>di <Plug>VimspectorBalloonEval

      " codeium
      let g:codeium_server_config = {
        \'portal_url': 'https://codeium.lan.theobjects.com',
        \'api_url': 'https://codeium.lan.theobjects.com/_route/api_server' }

      nnoremap <C-p> :FZF<CR>
      " for nerd commentary
      filetype plugin on
    '';

    extraLuaConfig = import ./neovim-config.lua.nix {
      inherit config;
      debugpy_env = python-debugpy;
    };
    plugins = with pkgs.vimPlugins; [
      coc-clangd
      coc-cmake
      coc-docker
      coc-git
      coc-html
      coc-json
      coc-nginx
      coc-pyright # only here to enable black format with coc-python. most of it's options are disabled in favour of pylance
      coc-sh
      coc-spell-checker
      coc-yaml
      fzfWrapper
      markdown-preview-nvim
      neorg-telescope
      nerdcommenter
      nerdtree
      nerdtree-git-plugin
      #nvim-dap
      #nvim-dap-python
      #nvim-dap-ui
      nvim-ufo
      telescope-coc-nvim
      telescope-file-browser-nvim
      telescope-fzf-native-nvim
      telescope-live-grep-args-nvim
      telescope-media-files-nvim
      telescope-nvim
      telescope-undo-nvim
      telescope-vim-bookmarks-nvim
      tokyonight-nvim
      vim-airline
      mypkgs.vim-codeium
      vim-bufkill
      vim-fugitive
      vim-gitgutter
      vim-markdown-toc
      mypkgs.vim-perforce
      vim-surround
      vim-surround
      vimspector
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
  home.shellAliases = {
    ca = ''eval "$(micromamba shell hook --shell=bash)" && micromamba activate base && micromamba activate --stack $ORSROOT/dragonfly_python_environment_linux'';
  };

  # Home Manager is pretty good at managing dotfiles. The primary way to manage
  # plain files is through 'home.file'.
  home.file = {
    # # Building this configuration will create a copy of 'dotfiles/screenrc' in
    # # the Nix store. Activating the configuration will then make '~/.screenrc' a
    # # symlink to the Nix store copy.
    # ".screenrc".source = dotfiles/screenrc;

    ".gitignore".source = ./gitignore.global;
    ".sd" = {
      source = ./script-directory;
      recursive = true;
      executable = true;
    };
    ".config/vimspector/gadgets/linux/debugpy".source = config.lib.file.mkOutOfStoreSymlink debugpy_path;
    ".config/vimspector/codelldb".source = config.lib.file.mkOutOfStoreSymlink codelldb_path;
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
