# This file defines overlays
{inputs, ...}: rec {
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
  unstable-packages = final: _prev: let
    inherit (final) system;

    patches = [
      {
        # patch for lldap: https://github.com/NixOS/nixpkgs/pull/268168
        url = "https://patch-diff.githubusercontent.com/raw/NixOS/nixpkgs/pull/268168.patch";
        hash = "sha256-WIMDnmZV0eL1eFVD0ldHUBrulZWsjdFOmcN4i8+RgFA=";
      }
    ];
    originPkgs = inputs.nixpkgs-unstable.legacyPackages.${system};
    nixpkgs-unstable = originPkgs.applyPatches {
      name = "nixpkgs-patched";
      src = inputs.nixpkgs;
      #patches = map originPkgs.fetchpatch patches;
    };
  in {
    unstable = import nixpkgs-unstable {
      inherit (final) system;
      config.allowUnfree = true;
      overlays = [my_vim_plugins];
    };
  };
}
