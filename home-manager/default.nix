{
  config,
  pkgs,
  mypkgs,
  lib,
  ...
}: let
  # vimspector debuggers
  python-debugpy = pkgs.python310.withPackages (ps: with ps; [debugpy]);
  debugpy_path = python-debugpy + "/lib/python3.10/site-packages/debugpy";

  codelldb = pkgs.vscode-extensions.vadimcn.vscode-lldb.overrideAttrs (finalAttrs: previousAttrs: {lldb = pkgs.lldb_16;});
  codelldb_path = "${codelldb}/share/vscode/extensions/${codelldb.vscodeExtPublisher}.${codelldb.vscodeExtName}";
  vimspector_configuration = {
    adapters = {
      CodeLLDB = {
        command = [
          "${codelldb_path}/adapter/codelldb"
          "--port"
          "\${unusedLocalPort}"
        ];
        configuration = {
          args = [];
          cargo = {};
          cwd = "\${workspaceRoot}";
          env = {};
          name = "lldb";
          terminal = "integrated";
          type = "lldb";
        };
        name = "CodeLLDB";
        port = "\${unusedLocalPort}";
        type = "CodeLLDB";
      };
      debugpy = {
        command = [
          "${python-debugpy}/bin/python3"
          "${debugpy_path}/adapter"
        ];
        configuration = {
          python = "${python-debugpy}/bin/python3";
        };
        custom_handler = "vimspector.custom.python.Debugpy";
        name = "debugpy";
      };
    };

    multi-session = {
      host = "\${host}";
      port = "\${port}";
    };
  };
  neovim-extraLuaConfig = import ./neovim-config.lua.nix {
    inherit config;
  };
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
    python311Packages.pygments
    thefuck
    xsel
    pigz # fast extraction for gz files
    pixz # fast extraction for xz files
  ];
  programs = {
    bash.enable = true;
    direnv.enable = true;
    zoxide.enable = true;
    zsh = {
      enable = true; # don't forget to add   `environment.pathsToLink = [ "/share/zsh" ];` to the system environment
      enableAutosuggestions = true;
      history = {
        size = 100 * 1000;
        save = 100 * 1000;
        share = true;
        ignorePatterns = ["rm *" "pkill *"];
      };
      oh-my-zsh = {
        enable = true;
        plugins = [
          "git"
          "thefuck"
          "docker"
          "docker-compose"
          "celery" # adds completion for python celery
          "zoxide" # simple naviation with z and history
          "tmux" # adds aliases to tmux
          "extract" # creates a command extract and alias x to quickly extract files
          "dircycle" # doesn't seem to work on mini-nix -- let's me use `ctrl + shift + <left/right>` to cycle through my cd paths like a browser would
          "rsync" # adds alias like rsync-copy rsync-move
          "copypath" # copies the absolute path to the file or dir
          "colored-man-pages" # automatically color man pages. I can also preprend `colored` e.g. `colored git help clone`, to try and get colours for terminal output
          "cp" # create alias to cpv: copies with progress bar using rsync
          "copyfile" # copies the content of <file> to my clipboard. e.g. `copyfile temp.txt`
        ];
        theme = "robbyrussell";
      };
    };

    bat.enable = true; # a cat like tool, but with wings?
    #fish.enable = true;
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
        coc.preferences.formatOnSaveFiletypes = ["python" "nix" "json" "cmake" "cpp"];
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
      " set the mapleader to the spacebar
      " vim.g.mapleader = "<Space>"
      let mapleader = " "

      noremap <silent>to :tabprevious<CR>
      noremap <silent>ti :tabnext<CR>
      noremap <silent>tn :tabnew<CR>
      set number relativenumber expandtab shiftwidth=4 softtabstop=4 smarttab
      nnoremap <C-Left> <C-W>h
      nnoremap <C-Down> <C-W>j
      nnoremap <C-Up> <C-W>k
      nnoremap <C-Right> <C-W>l
      nnoremap <C-h> <C-W>h
      nnoremap <C-j> <C-W>j
      nnoremap <C-k> <C-W>k
      nnoremap <C-l> <C-W>l
    '';

    extraLuaConfig = neovim-extraLuaConfig.extra_lua_config + (lib.optionalString config.programs.neovim.coc.enable neovim-extraLuaConfig.coc_config);
    plugins = with pkgs.vimPlugins; [
      {
        plugin = coc-clangd;
        config = ''
          vim.api.nvim_set_keymap('n', 'gt', ':CocCommand clangd.switchSourceHeader<CR>', {silent = true})
        '';
        type = "lua";
      }
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
      {
        plugin = fzfWrapper;
        config = ''nnoremap <C-p> :FZF<CR>'';
      }
      markdown-preview-nvim
      neorg-telescope

      {
        plugin = nerdcommenter;
        config = ''filetype plugin on'';
      }

      {
        plugin = nerdtree;
        config = ''nnoremap <C-t> :NERDTreeFind<CR>'';
      }
      nerdtree-git-plugin
      #nvim-dap
      #nvim-dap-python
      #nvim-dap-ui
      {
        plugin = nvim-ufo;
        config = ''
          vim.o.foldcolumn = '1' -- '0' is not bad
          vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
          vim.o.foldlevelstart = 99
          vim.o.foldenable = true

          -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
          vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
          vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
        '';
        type = "lua";
      }

      {
        plugin = telescope-coc-nvim;
        config = ''
          noremap <leader>fws :Telescope coc workspace_symbols<CR>
          noremap <leader>fs :Telescope coc document_symbols<CR>
          noremap <leader>la :Telescope coc file_code_actions<CR>
        '';
      }
      telescope-file-browser-nvim
      telescope-fzf-native-nvim
      telescope-live-grep-args-nvim
      telescope-media-files-nvim
      {
        plugin = telescope-nvim;
        config = ''
          -- require('dap-python').setup('${python-debugpy.outPath}/bin/python3');
          local builtin = require('telescope.builtin')
          local telescope = require("telescope")
          local telescopeConfig = require("telescope.config")
          -- Clone the default Telescope configuration
          local vimgrep_arguments = { unpack(telescopeConfig.values.vimgrep_arguments) }

          -- I want to search in hidden/dot files.
          table.insert(vimgrep_arguments, "--hidden")
          -- I don't want to search in the `.git` directory.
          table.insert(vimgrep_arguments, "--ignore-file")
          table.insert(vimgrep_arguments, "${config.home.homeDirectory}/.gitignore")
          telescope.setup({
          defaults = {
               -- `hidden = true` is not supported in text grep commands.
               vimgrep_arguments = vimgrep_arguments,
          },
          pickers = {
               find_files = {
                       -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                       find_command = { "rg", "--files", "--hidden", "--ignore-file", "${config.home.homeDirectory}/.gitignore" };
               },
          },
          })

          vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
          vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
          vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
          vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
        '';
        type = "lua";
      }

      telescope-undo-nvim
      telescope-vim-bookmarks-nvim

      {
        plugin = tokyonight-nvim;
        config = ''
          colorscheme tokyonight-moon
        '';
      }
      vim-airline

      {
        plugin = vim-codeium;
        config = ''
          let g:codeium_server_config = {'portal_url': 'https://codeium.lan.theobjects.com', 'api_url': 'https://codeium.lan.theobjects.com/_route/api_server' }
        '';
      }

      vim-bufkill
      vim-fugitive
      vim-gitgutter
      vim-markdown-toc

      {
        plugin = vim-perforce;
        config = ''
          " open file on perforce on save
          let g:perforce_open_on_save = 1
          " saving on change is preferred, at least in neovim.
          " writing a buffer to disk is a change.
          " editing a buffer is not a change.
          let g:perforce_open_on_change = 1
          " don't prompt on every save
          let g:perforce_prompt_on_open = 0
        '';
      }
      vim-surround

      {
        plugin = vimspector;
        config = ''
          " vim.g.vimspector_enable_mappings = 'HUMAN'
          let g:vimspector_enable_mappings = 'VISUAL_STUDIO'
          let g:vimspector_base_dir = expand('$HOME/.config/vimspector-test')

          " Vim inspector
          " mnemonic 'di' = 'debug inspect' (pick your own, if you prefer!)
          " for normal mode - the word under the cursor
          nmap <Leader>di <Plug>VimspectorBalloonEval

          " nmap for visual mode, the visually selected text
          xmap <Leader>di <Plug>VimspectorBalloonEval

          " Reset
          nmap <Leader>vr <Plug>VimspectorReset<CR>
        '';
      }
      {
        plugin = tagbar;
        config = ''noremap <silent>tt :TagbarToggle<CR>'';
      }
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
    ca = ''eval "$(micromamba shell hook --shell=bash)" && micromamba activate --stack $ORSROOT/dragonfly_python_environment_linux'';
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
    #    ".config/vimspector/gadgets/linux/debugpy".source = config.lib.file.mkOutOfStoreSymlink debugpy_path;
    #    ".config/vimspector/gadgets/linux/codelldb".source = config.lib.file.mkOutOfStoreSymlink codelldb_path;
    ".config/vimspector/gadgets/linux/.gadgets.json".source = pkgs.writeText ".gadgets.json" (builtins.toJSON vimspector_configuration);
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
