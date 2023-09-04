{
  #users.users.nix-admin = {
  #  isSystemUser = true;
  #  group = "nix-admin";
  #};
  #users.groups.nix-admin = {};
  security.sudo.extraRules = [
    {
      groups = ["nix-admin"];
      commands = [
        {
          command = "/run/current-system/sw/bin/nixos-rebuild";
          options = ["SETENV" "NOPASSWD"];
        }
      ];
    }
  ];
}
