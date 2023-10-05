# This file defines overlays
{inputs, ...}: {
  # This one brings our custom packages from the 'pkgs' directory
  # additions = final: _prev: import ../pkgs {pkgs = final;};

  # This one contains whatever you want to overlay
  # You can change versions, add patches, set compilation flags, anything really.
  # https://nixos.wiki/wiki/Overlays
  my_vim_plugins = final: prev: {
    vimPlugins =
      prev.vimPlugins
      // {
        vim-codeium = prev.vimUtils.buildVimPlugin {
          name = "codeium.vim";
          src = inputs.vim-codeium;
        };
        vim-perforce = prev.vimUtils.buildVimPlugin {
          name = "vim-perforce";
          src = inputs.vim-perforce;
        };

        spelunker-vim = prev.vimUtils.buildVimPlugin {
          name = "spelunker.vim";
          src = inputs.vim-spelunker;
        };
      };
  };

  # When applied, the unstable nixpkgs set (declared in the flake inputs) will
  # be accessible through 'pkgs.unstable'
  unstable-packages = final: _prev: {
    unstable = import inputs.nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
    };
  };
}
