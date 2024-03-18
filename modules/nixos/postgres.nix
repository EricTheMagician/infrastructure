{
  pkgs,
  config,
  inputs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkEnableOption;
  cfg = config.my.postgresql;
  immich_enabled = builtins.hasAttr "immichPostgreSQLInit" config.systemd.services;
in {
  disabledModules = ["services/backup/postgresql-backup.nix"];
  imports = [(inputs.nixpkgs-unstable + "/nixos/modules/services/backup/postgresql-backup.nix")];

  options.my.postgresql = {
    enable = mkEnableOption "postgresql";
  };
  config = mkIf cfg.enable {
    services.postgresql = {
      # https://nixos.wiki/wiki/PostgreSQL
      enable = true;
      #package = pkgs.unstable.postgresql_16;
      package = pkgs.postgresql_16.withPackages (p: (lib.optional immich_enabled (pkgs.pgvecto_rs.override {postgres = pkgs.postgresql_16;}))); #.override {postgresql = pkgs.unstable.postgresql_16;})));
      settings = mkIf immich_enabled {
        shared_preload_libraries = "vectors.so";
      };
      identMap = ''
        # ArbitraryMapName systemUser DBUser
           superuser_map      root      postgres
           superuser_map      postgres  postgres
           # Let other names login as themselves
           superuser_map      /^(.*)$   \1
      '';
      authentication = pkgs.lib.mkOverride 10 ''
        #type database  DBuser  auth-method optional_ident_map
        local sameuser  all     peer        map=superuser_map
        local all postgres ident map=superuser_map
        #type database DBuser origin-address auth-method
        host  sameuser  all     ::1/128   md5
        host  sameuser  all     127.0.0.1/32   md5
        # for docker only
        host sameuser all 172.16.0.0/12 md5
        # for tailscale network
        host sameuser all 100.64.0.0/10 md5
      '';
    };

    services.postgresqlBackup = {
      enable = true;
    };
    my.backups.paths = [config.services.postgresqlBackup.location];
  };
}
