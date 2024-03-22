# This file defines overlays
{inputs, ...}: rec {
  # This one brings our custom packages from the 'packages' directory
  additions = final: _prev: import ./packages final _prev;

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
  unstable-packages = final: _prev: let
    inherit (final) system;

    patches = [
      {
        # add's stirling-pdf
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/283305.patch";
        hash = "sha256-ZeNOC2ByusDsp7juf+QdMY43Fg2zfv5+ZTOH3/joItA=";
      }
      {
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/289664.diff";
        hash = "sha256-ZzodY4kr8tq/Vo0kZEwTzxDkuiPx7xRqCcvTkb/cltk=";
      }
    ];
    originPkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    nixpkgs-unstable = originPkgs.applyPatches {
      name = "nixpkgs-patched";
      src = inputs.nixpkgs-unstable;
      patches = map originPkgs.fetchpatch patches;
    };
  in {
    unstable = import nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = final.config.allowUnfree;
      overlays = [my_vim_plugins inputs.nvim-codeium.overlays.${system}.default];
    };
  };

  other-packages = final: prev: {
    inherit (inputs.flox.packages.x86_64-linux) flox;
  };
}
