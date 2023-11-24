{
  config,
  pkgs,
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
in {
  # This value determines the Home Manager release that your configuration is
  # compatible with. This helps avoid breakage when a new Home Manager release
  # introduces backwards incompatible changes.
  #
  # You should not change this value, even if you update Home Manager. If you do
  # want to update the value, then make sure to first check the Home Manager
  # release notes.
  home = {
    stateVersion = "23.05"; # Please read the comment before changing.
    enableNixpkgsReleaseCheck = false;

    # The home.packages option allows you to install Nix packages into your
    # environment.
    packages = with pkgs; [
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
  };
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

  programs.neovim = import ./neovim/home-manager.nix {
    inherit pkgs;
    inherit config;
    inherit (pkgs) lib;
  }; #  home.file.".config/fish/config.fish".text = ''
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
    ".sd/nix/flake/update".source = pkgs.writeShellScript "update-input" ''
      # little script to select which nix flake input to update
      # courtesy of @vimjoyer
      input=$(                                           \
        nix flake metadata --json                        \
        | ${pkgs.jq}/bin/jq ".locks.nodes.root.inputs[]" \
        | sed "s/\"//g"                                  \
        | ${pkgs.fzf}/bin/fzf)
      nix flake lock --update-input $input
    '';
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
