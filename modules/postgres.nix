{
  pkgs,
  config,
  ...
}: {
  services.postgresql = {
    # https://nixos.wiki/wiki/PostgreSQL
    enable = true;
    package = pkgs.unstable.postgresql_16;
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
    '';
  };

  services.postgresqlBackup = {
    enable = true;
  };
  system_borg_backup_paths = [config.services.postgresqlBackup.location];
}
