{pkgs, ...}: {
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
    '';
  };

  services.postgresqlBackup ={
  enable=true;
  };
}
