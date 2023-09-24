{
  config,
  pkgs,
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
    nerdfonts
    rclone
    unzip
    # viber
    btop
    dua
    #byobu
    tmux
    ##
    thefuck
    xsel
    pigz # fast extraction for gz files
    pixz # fast extraction for xz files
    fd
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
          "zoxide" # simple navigation with z and history
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

    tmux = {
      enable = true;
      terminal = "screen-256color";
      shortcut = "a";
      shell = "${pkgs.zsh}/bin/zsh";
      sensibleOnTop = true;
      baseIndex = 1;

      tmuxinator.enable = true;
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
    withNodeJs = true;
    extraPackages = with pkgs; [
      efm-langserver # for efm lang server
      nil # for nix language server
      clang-tools_16 # clang-format
      cmake-format
      neocmakelsp
      ruff-lsp
      nodePackages.pyright
      nodePackages.cspell
      pylyzer
      jsonfmt
      alejandra # nix formatter
      black # python formatter
    ];

    extraConfig = ''
      " disbles mouse in neovim in general
      " set mouse=
      " set the mapleader to the spacebar
      " let g:mapleader = " "
      " let g:maplocalleader = " "

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
      # first, setup telescope
      {
        plugin = telescope-nvim;
        config = ''
          -- Configure Telescope
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
               mappings = {
                     i = {
                         ['<C-u>'] = false,
                         ['<C-d>'] = false,
                     },
               },
          },
          pickers = {
               find_files = {
                       -- `hidden = true` will still show the inside of `.git/` as it's not `.gitignore`d.
                       find_command = { "rg", "--files", "--hidden", "--ignore-file", "${config.home.homeDirectory}/.gitignore" };
               },
          },
          })

          -- See `:help telescope.builtin`
          vim.keymap.set('n', '<leader>?', require('telescope.builtin').oldfiles, { desc = '[?] Find recently opened files' })
          vim.keymap.set('n', '<leader><space>', require('telescope.builtin').buffers, { desc = '[ ] Find existing buffers' })
          vim.keymap.set('n', '<leader>/', function()
            -- You can pass additional configuration to telescope to change theme, layout, etc.
            require('telescope.builtin').current_buffer_fuzzy_find(require('telescope.themes').get_dropdown {
              winblend = 10,
              previewer = false,
            })
          end, { desc = '[/] Fuzzily search in current buffer' })

          vim.keymap.set('n', '<leader>gf', require('telescope.builtin').git_files, { desc = 'Search [G]it [F]iles' })
          vim.keymap.set('n', '<leader>ff', require('telescope.builtin').find_files, { desc = '[F]ind [F]iles' })
          vim.keymap.set('n', '<leader>fh', require('telescope.builtin').help_tags, { desc = '[F]ind [H]elp' })
          vim.keymap.set('n', '<leader>fw', require('telescope.builtin').grep_string, { desc = '[F]ind current [W]ord' })
          vim.keymap.set('n', '<leader>fg', require('telescope.builtin').live_grep, { desc = '[F]ind by [G]rep' })
          vim.keymap.set('n', '<leader>fd', require('telescope.builtin').diagnostics, { desc = '[F]ind [D]iagnostics' })
          vim.keymap.set('n', '<leader>fr', require('telescope.builtin').resume, { desc = '[F]ind [R]resume' })
          -- vim.keymap.set('n', '<leader>ff', builtin.find_files, {})
          -- vim.keymap.set('n', '<leader>fg', builtin.live_grep, {})
          -- vim.keymap.set('n', '<leader>fb', builtin.buffers, {})
          -- vim.keymap.set('n', '<leader>fh', builtin.help_tags, {})
          -- End configure Telescope
        '';
        type = "lua";
      }
      nvim-treesitter-parsers.python
      nvim-treesitter-parsers.awk
      nvim-treesitter-parsers.bash
      nvim-treesitter-parsers.c
      nvim-treesitter-parsers.cpp
      nvim-treesitter-parsers.cmake
      nvim-treesitter-parsers.cuda
      nvim-treesitter-parsers.python
      nvim-treesitter-parsers.csv
      nvim-treesitter-parsers.diff
      nvim-treesitter-parsers.doxygen
      nvim-treesitter-parsers.git_config
      nvim-treesitter-parsers.git_rebase
      nvim-treesitter-parsers.gitattributes
      nvim-treesitter-parsers.gitcommit
      nvim-treesitter-parsers.gitignore
      nvim-treesitter-parsers.glsl
      nvim-treesitter-parsers.hjson
      nvim-treesitter-parsers.html
      nvim-treesitter-parsers.http
      nvim-treesitter-parsers.ini
      nvim-treesitter-parsers.jq
      nvim-treesitter-parsers.jsdoc
      nvim-treesitter-parsers.json
      nvim-treesitter-parsers.latex
      nvim-treesitter-parsers.markdown
      nvim-treesitter-parsers.meson
      nvim-treesitter-parsers.ninja
      nvim-treesitter-parsers.nix
      nvim-treesitter-parsers.norg
      nvim-treesitter-parsers.rust
      nvim-treesitter-parsers.php
      nvim-treesitter-parsers.perl
      nvim-treesitter-parsers.python
      nvim-treesitter-parsers.regex
      nvim-treesitter-parsers.requirements
      nvim-treesitter-parsers.robot
      nvim-treesitter-parsers.strace
      nvim-treesitter-parsers.terraform
      nvim-treesitter-parsers.tsv
      nvim-treesitter-parsers.typescript
      nvim-treesitter-parsers.vim
      nvim-treesitter-parsers.xml
      nvim-treesitter-parsers.yaml
      nvim-treesitter-textobjects
      {
        plugin = nvim-treesitter;
        config = ''
          -- [[ Configure Treesitter ]]
          -- See `:help nvim-treesitter`
          require('nvim-treesitter.configs').setup {
            -- Add languages to be installed here that you want installed for treesitter
           --  ensure_installed = { 'c', 'cpp', 'go', 'lua', 'python', 'rust', 'tsx', 'javascript', 'typescript', 'vimdoc', 'vim' },

            highlight = { enable = true },
            indent = { enable = true },
            incremental_selection = {
              enable = true,
              keymaps = {
                init_selection = '<c-space>',
                node_incremental = '<c-space>',
                scope_incremental = '<c-s>',
                node_decremental = '<M-space>',
              },
            },
            textobjects = {
              select = {
                enable = true,
                lookahead = true, -- Automatically jump forward to textobj, similar to targets.vim
                keymaps = {
                  -- You can use the capture groups defined in textobjects.scm
                  ['aa'] = '@parameter.outer',
                  ['ia'] = '@parameter.inner',
                  ['af'] = '@function.outer',
                  ['if'] = '@function.inner',
                  ['ac'] = '@class.outer',
                  ['ic'] = '@class.inner',
                },
              },
              move = {
                enable = true,
                set_jumps = true, -- whether to set jumps in the jumplist
                goto_next_start = {
                  [']m'] = '@function.outer',
                  [']]'] = '@class.outer',
                },
                goto_next_end = {
                  [']M'] = '@function.outer',
                  [']['] = '@class.outer',
                },
                goto_previous_start = {
                  ['[m'] = '@function.outer',
                  ['[['] = '@class.outer',
                },
                goto_previous_end = {
                  ['[M'] = '@function.outer',
                  ['[]'] = '@class.outer',
                },
              },
              swap = {
                enable = true,
                swap_next = {
                  ['<leader>a'] = '@parameter.inner',
                },
                swap_previous = {
                  ['<leader>A'] = '@parameter.inner',
                },
              },
            },
          }
        '';
        type = "lua";
      }
      {
        # spelunker is a spell checker
        plugin = spelunker-vim;
      }
      {
        plugin = efmls-configs-nvim;
        type = "lua";
        config = ''

          -- Register linters and formatters per language
          local black = require('efmls-configs.formatters.black')
          local clang_format = require('efmls-configs.formatters.clang_format')
          local alejandra = require('efmls-configs.formatters.alejandra')
          local cspell = require('efmls-configs.linters.cspell')
          local languages = {
            -- ['='] = {cspell,},
            python = { black,  },
            cpp = { clang_format,  },
            nix = { alejandra,  },
          }

          local efmls_config = {
            filetypes = vim.tbl_keys(languages),
            settings = {
              rootMarkers = { '.git/' },
              languages = languages,
            },
            init_options = {
              documentFormatting = true,
              documentRangeFormatting = true,
            },
          }

          require('lspconfig').efm.setup(vim.tbl_extend('force', efmls_config, {
            -- Pass your custom lsp config below like on_attach and capabilities
            --
            -- on_attach = on_attach,
            capabilities = require("cmp_nvim_lsp").default_capabilities(),
          }))
          local lsp_fmt_group = vim.api.nvim_create_augroup('LspFormattingGroup', {})
          vim.api.nvim_create_autocmd('BufWritePost', {
            group = lsp_fmt_group,
            callback = function()
              local efm = vim.lsp.get_active_clients({ name = 'efm' })

              if vim.tbl_isempty(efm) then
                return
              end

            vim.lsp.buf.format({ name = 'efm' })
              end,
          })
        '';
      }
      {
        plugin = neorg;
        config = ''
          require("neorg").setup {
              load = {
                  ["core.defaults"] = {},
                  ["core.concealer"] = {},
                  ["core.dirman"] = {
                    config = {
                      workspaces = {
                        notes = "~/git/notes",
                      },
                      default_workspace = "notes",
                    },
                  },
              },
          }
        '';
        type = "lua";
      }
      neorg-telescope
      luasnip
      friendly-snippets
      cmp-nvim-lsp
      cmp-nvim-lsp-document-symbol
      cmp-nvim-lsp-signature-help
      which-key-nvim
      {
        plugin = nvim-lspconfig;
        type = "lua";
        config = ''
            -- Diagnostic keymaps
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev, { desc = 'Go to previous diagnostic message' })
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next, { desc = 'Go to next diagnostic message' })
            vim.keymap.set('n', '<leader>e', vim.diagnostic.open_float, { desc = 'Open floating diagnostic message' })
            vim.keymap.set('n', '<leader>q', vim.diagnostic.setloclist, { desc = 'Open diagnostics list' })

            local lspconfig = require('lspconfig')
            local capabilities = require("cmp_nvim_lsp").default_capabilities()
            lspconfig.pyright.setup {capabilities = capabilities}
            lspconfig.nil_ls.setup {capabilities = capabilities}
            lspconfig.clangd.setup {capabilities = capabilities}
            lspconfig.cmake.setup {capabilities = capabilities}
            lspconfig.ruff_lsp.setup {
                cmd = { "${pkgs.ruff-lsp}/bin/ruff-lsp" },
                capabilities = capabilities
            }


            -- Global mappings.
            -- See `:help vim.diagnostic.*` for documentation on any of the below functions
            vim.keymap.set('n', '<space>e', vim.diagnostic.open_float)
            vim.keymap.set('n', '[d', vim.diagnostic.goto_prev)
            vim.keymap.set('n', ']d', vim.diagnostic.goto_next)
            vim.keymap.set('n', '<space>q', vim.diagnostic.setloclist)

            -- Use LspAttach autocommand to only map the following keys
            -- after the language server attaches to the current buffer
            vim.api.nvim_create_autocmd('LspAttach', {

            group = vim.api.nvim_create_augroup('UserLspConfig', {}),
            callback = function(ev)
            -- Enable completion triggered by <c-x><c-o>
            vim.bo[ev.buf].omnifunc = 'v:lua.vim.lsp.omnifunc'

            -- Buffer local mappings.
            -- See `:help vim.lsp.*` for documentation on any of the below functions
            local opts = { buffer = ev.buf }
            vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, opts)
            vim.keymap.set('n', 'gd', vim.lsp.buf.definition, opts)
            vim.keymap.set('n', 'K', vim.lsp.buf.hover, opts)
            vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, opts)
            vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, opts)
            vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, opts)
            vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, opts)
            vim.keymap.set('n', '<space>wl', function()
                  vim.print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
              end, opts)
            vim.keymap.set('n', '<space>D', vim.lsp.buf.type_definition, opts)
            vim.keymap.set('n', '<space>rn', vim.lsp.buf.rename, opts)
            vim.keymap.set({ 'n', 'v' }, '<space>ca', vim.lsp.buf.code_action, opts)
            vim.keymap.set('n', 'gr', vim.lsp.buf.references, opts)
            vim.keymap.set('n', '<space>f', function()
            vim.lsp.buf.format { async = true }
            end, opts)
            end,
          })

        '';
      }
      indent-blankline-nvim
      fidget-nvim
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

      {
        plugin = nvim-ufo;
        config = ''
          vim.o.foldcolumn = '1' -- '0' is not bad
          vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
          vim.o.foldlevelstart = 99
          vim.o.foldepythonnable = true

          -- Using ufo provider need remap `zR` and `zM`. If Neovim is 0.6.1, remap yourself
          vim.keymap.set('n', 'zR', require('ufo').openAllFolds)
          vim.keymap.set('n', 'zM', require('ufo').closeAllFolds)
        '';
        type = "lua";
      }

      telescope-file-browser-nvim
      telescope-fzf-native-nvim
      telescope-live-grep-args-nvim
      telescope-media-files-nvim
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

      cmp-async-path
      cmp-fuzzy-path
      cmp-nvim-lsp
      cmp-nvim-lsp-document-symbol
      cmp-nvim-lsp-signature-help
      {
        plugin = nvim-cmp;
        type = "lua";
        config = ''
          -- configure cmp
          -- See `:help cmp`
          local cmp = require 'cmp'
          local luasnip = require 'luasnip'
          require('luasnip.loaders.from_vscode').lazy_load()
          luasnip.config.setup {}

          cmp.setup {
            snippet = {
              expand = function(args)
                luasnip.lsp_expand(args.body)
              end,
            },
            mapping = cmp.mapping.preset.insert {
              ['<C-n>'] = cmp.mapping.select_next_item(),
              ['<C-p>'] = cmp.mapping.select_prev_item(),
              ['<C-d>'] = cmp.mapping.scroll_docs(-4),
              ['<C-f>'] = cmp.mapping.scroll_docs(4),
              ['<C-Space>'] = cmp.mapping.complete {},
              ['<CR>'] = cmp.mapping.confirm {
                behavior = cmp.ConfirmBehavior.Replace,
                select = true,
              },
              ['<Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_next_item()
                -- elseif luasnip.expand_or_locally_jumpable() then
                --   luasnip.expand_or_jump()
                else
                  fallback()
                end
              end, { 'i', 's' }),
              ['<S-Tab>'] = cmp.mapping(function(fallback)
                if cmp.visible() then
                  cmp.select_prev_item()
                elseif luasnip.locally_jumpable(-1) then
                  luasnip.jump(-1)
                else
                  fallback()
                end
              end, { 'i', 's' }),
            },
            sources = {
              { name = 'nvim_lsp' },
              { name = 'async_path' },
              { name = 'fuzzy_path'},
              -- { name = 'luasnip' },

            },
          }
          -- end configure cmp

        '';
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
