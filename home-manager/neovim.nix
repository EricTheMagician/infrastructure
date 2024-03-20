{
  config,
  pkgs,
  lib,
  inputs,
  ...
}: let
  inherit (lib) mkIf mkEnableOption genAttrs optionalAttrs optionals;
  cfg = config.my.programs.neovim;
  enable_dap =
    cfg.languages.python.enable || cfg.languages.cpp.enable;
in {
  imports = [
    inputs.nixvim.homeManagerModules.nixvim
  ];
  options.my.programs.neovim = {
    enable = mkEnableOption "enable neovim";
    languages = genAttrs ["python" "cpp" "nix"] (language: {enable = mkEnableOption "enable formatters and linters for ${language}";});
    features = {
      codeium = {
        enable = mkEnableOption "enable codeium";
        enterprise = mkEnableOption "enable codeium enterprise";
      };
      perforce.enable = mkEnableOption "perforce";
    };
  };

  config = mkIf cfg.enable {
    programs.nixvim = {
      enable = true;
      viAlias = true;
      vimAlias = true;
      globals = {
        # sets the leader key to space
        mapleader = " ";
        maplocalleader = " ";
      };
      options = {
        number = true;
        relativenumber = true;
        expandtab = true;
        smartindent = true;
        tabstop = 4;
        softtabstop = 4;
        shiftwidth = 4;

        #      highlight = {
        #      Comment.bold = true;
        #      };
      };
      clipboard = {
        # register = "wl-copy";
        providers = {
          wl-copy.enable = true;
          xsel.enable = true;
        };
      };
      colorschemes = {
        tokyonight.enable = true;
        # gruvbox.enable = true;
      };
      extraPlugins = with pkgs.vimPlugins;
        [
          vim-bufkill # for :BD to close buffer without killing it
        ]
        ++ optionals cfg.features.perforce.enable [
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
        ];

      keymaps = [
        {
          key = "<leader>fb";
          action = ":Telescope file_browser path=%:p:h select_buffer=true<CR>";
        }
        # {
        #   key = "tn";
        #   action = ":tabnew<CR>";
        # }
        {
          key = "ti";
          # action = ":tabnext<CR>";
          action = ":bn<CR>";
        }
        {
          key = "to";
          # action = ":tabprevious<CR>";
          action = ":bp<CR>";
        }
      ];

      plugins = {
        airline.enable = true;
        bufferline.enable = true;
        nix-develop.enable = true;
        fugitive.enable = true;
        lastplace.enable = true;
        nvim-osc52 = {
          enable = true;
          keymaps.enable = true;
        };
        comment-nvim = {
          enable = true;
        };
        codeium-nvim = {
          inherit (cfg.features.codeium) enable;
          extraOptions = mkIf cfg.features.codeium.enterprise {
            enterprise_mode = true;
            api = {
              host = "codeium.lan.theobjects.com";
              port = 443;
              #path = "/_route/api_server";
              #portal_url = "codeium.lan.theobjects.com:443";
            };
          };
        };
        dap = {
          enable = cfg.languages.python.enable || cfg.languages.cpp.enable;
          adapters.executables = {
            cpp = optionalAttrs cfg.languages.cpp.enable {
              command = "${pkgs.gdb}/bin/gdb";
              args = ["-i" "dap"];
            };
          };
          extensions.dap-ui.enable = enable_dap;
          extensions.dap-virtual-text.enable = enable_dap;
          extensions.dap-python = {
            inherit (cfg.languages.python) enable;
          };
        };
        lsp = {
          enable = true;
          servers = {
            bashls.enable = true;
            clangd = {
              inherit (cfg.languages.cpp) enable;
            };
            cmake = {
              inherit (cfg.languages.cpp) enable;
            };
            efm.enable = true; # for formatting and linters
            jsonls.enable = true;
            # nil_ls = {
            #   inherit (cfg.languages.nix) enable;
            #   settings.formatting.command = ["${pkgs.alejandra}/bin/alejandra"];
            # };
            nixd = {
              inherit (cfg.languages.nix) enable;
              settings.formatting.command = "${pkgs.alejandra}/bin/alejandra";
            };
            pyright = {inherit (cfg.languages.python) enable;};
            pylsp = {
              enable = true;
              settings.plugins = {
                black.enabled = true;
                pylint.enabled = true;
                # pylsp_mypy.enabled = true;
              };
            };
            yamlls.enable = true;
          };
          keymaps.diagnostic = {
            "<leader>j" = "goto_next";
            "<leader>k" = "goto_prev";
          };
          keymaps.lspBuf = {
            K = "hover";
            gD = "references";
            gd = "definition";
            gi = "implementation";
            gt = "type_definition";
            ft = "format";
            rn = "rename";
          };
        };
        efmls-configs = {
          enable = true;
          setup = {
            c = optionalAttrs cfg.languages.cpp.enable {
              formatter = "clang_format";
            };
            cpp = optionalAttrs cfg.languages.cpp.enable {
              formatter = "clang_format";
            };
            cmake = optionalAttrs cfg.languages.cpp.enable {
              #formatter = "gersemi";
              linter = ["cmake_lint"];
            };
            python = optionalAttrs cfg.languages.python.enable {
              formatter = "black";
              linter = ["ruff" "mypy"];
            };
            nix = optionalAttrs cfg.languages.nix.enable {
              formatter = "alejandra";
              linter = ["statix"];
            };

            docker = {linter = ["hadolint"];};
            json = {
              linter = "jq";
              formatter = "jq";
            };
            yaml = {
              formatter = "yq";
              linter = ["yamllint"];
            };
            markdown = {
              formatter = "mdformat";
              linter = ["markdownlint"];
            };
            #
            bash = {
              formatter = "beautysh";
              linter = ["bashate"];
            };
          };
        };
        luasnip.enable = true;
        cmp = {
          enable = true;
          autoEnableSources = true;
          settings = {
            sources =
              [
                {name = "nvim_lsp";}
                {name = "path";}
                {name = "buffer";}
              ]
              ++ (lib.optional cfg.features.codeium.enable
                {name = "codeium";});
            mapping = {
              "<CR>" = "cmp.mapping.confirm({ select = true })";
              "<S-Tab>" = "cmp.mapping.select_prev_item()";
              "<Tab>" = ''
                function(fallback)
                  if cmp.visible() then
                    cmp.select_next_item()
                  else
                    fallback()
                  end
                end
              '';
            };
          };
        };
        cmp-nvim-lsp.enable = true;
        cmp-nvim-lsp-document-symbol.enable = true;
        cmp-nvim-lsp-signature-help.enable = true;
        surround.enable = true;
        oil.enable = true;
        treesitter = {
          enable = true;
          # folding = true;
        };
        treesitter-textobjects = {
          move = {enable = true;};
        };
        nvim-lightbulb = {
          enable = true;
          #  settings = optionalAttrs false {
          #    autocmd = {
          #       enabled = true;
          #        updatetime = 200;
          #       };
          #        float = {
          #           enabled = false;
          #            text = " 󰌶 ";
          #             win_opts = {
          #                border = "rounded";
          #              };
          #            };
          #            line = {
          #              enabled = false;
          #            };
          #            number = {
          #              enabled = false;
          #            };
          #            sign = {
          #              enabled = false;
          #              text = "󰌶";
          #            };
          #            status_text = {
          #              enabled = false;
          #              text = " 󰌶 ";
          #            };
          #            virtual_text = {
          #              enabled = true;
          #              text = "󰌶";
          #            };
          #          };
        };

        telescope = {
          enable = true;
          keymaps = {
            "<leader>fg" = {
              action = "live_grep";
              desc = "Telescope Live Grep";
            };
            "<leader>ff" = {
              action = "find_files";
              desc = "Telescope Find Files";
            };
            "<leader><space>" = {
              action = "buffers";
              desc = "Telescope Buffers";
            };
            "<leader>fd" = {
              action = "diagnostics";
              desc = "Telescope Diagnostics";
            };
            "<leader>fr" = {
              action = "resume";
              desc = "Telescope Resume";
            };
          };
          extensions = {
            media_files.enable = true;
            file_browser = {
              enable = true;
              hijackNetrw = true;
              hidden = true; # show hidden files
              grouped = false; # Group initial sorting by directories and then files.
              promptPath = true;
            };
          };
        };
      };
    };
  };
}
#

