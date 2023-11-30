{pkgs, ...}: {
  environment.systemPackages = [
    pkgs.unstable.vscode-with-extensions.override
    {
      vscodeExtensions = with pkgs.unstable.vscode-extensions;
        [
          # generatl development related packages
          ms-vscode-remote.remote-ssh
          eamodio.gitlens
          # ms-vscode.powershell
          # ms-azuretools.vscode-docker

          # python related packages
          ms-python.python
          ms-python.vscode-pylance
          ms-python.black-formatter

          # C++ related packages
          #ms-vscode.cpptools
          #ms-vscode.cmake-tools
          #xaver.clang-format

          # nix related packages
          bbenoist.nix
          arrterian.nix-env-selector
          jnoortheen.nix-ide
        ]
        ++ pkgs.vscode-utils.extensionsFromVscodeMarketplace
        [
        ];
    }
  ];
}
