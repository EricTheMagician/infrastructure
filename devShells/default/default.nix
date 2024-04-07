{
  pkgs,
  inputs,
  ...
}: let
  update-dns-python-script = pkgs.callPackage ../packages/nextdns-update {};
  host-json = pkgs.writeText "host.json" (builtins.toJSON (import ../common/dns/custom_domains.nix));
  update-dns-shell-script = pkgs.writeShellScriptBin "update-nextdns" ''
    API_KEY=$(sudo cat /run/secrets/nextdns/api_token)
    HOME_PROFILE=$(sudo cat /run/secrets/nextdns/profile/home)
    TAILSCALE_PROFILE=$(sudo cat /run/secrets/nextdns/profile/tailscale)
    ${update-dns-python-script.interpreter} ${update-dns-python-script.script} \
        --json-hosts-file ${host-json} \
        --api-key $API_KEY \
        --home-profile $HOME_PROFILE \
        --tailscale-profile $TAILSCALE_PROFILE
  '';
  update-adguard = pkgs.writeShellScriptBin "update-adguard" ''
    ${pkgs.unstable.deploy-rs}/bin/deploy -s --targets .#mini-nix.system .#thepodfather
  '';
  update-dns = pkgs.writeShellScriptBin "update-dns" ''
    ${pkgs.unstable.deploy-rs}/bin/deploy -s --targets .#mini-nix.system .#thepodfather .#headscale
  '';
in
  pkgs.mkShell {
    buildInputs = [pkgs.unstable.deploy-rs pkgs.unstable.sops pkgs.unstable.ssh-to-age pkgs.unstable.nix-build-uncached pkgs.unstable.statix update-adguard update-dns];
    shellHook = let
      pre-commit-check = inputs.nix-pre-commit-hooks.lib.${pkgs.system}.run {
        src = ./.;
        hooks = {
          alejandra.enable = true;
          nil.enable = true;
          statix.enable = true;
        };
      };
    in
      pre-commit-check.shellHook;
  }
