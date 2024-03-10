{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkOption types mkMerge mkEnableOption mkIf;
  cfg = config.my.tandoor-recipes;
  #create_database =
  #  import ../../functions/create_postgresql_db.nix
  #  {
  #    name = "tandoor_recipes";
  #    user_name = "tandoor_recipes";
  #    passwordFile = config.sops.secrets."tandoor/db_password".path;
  #    wantedBy = ["tandoor-recipes.service"];
  #    inherit config;
  #    inherit (pkgs) lib;
  #  };
in {
  options.my.tandoor-recipes = {
    enable = mkEnableOption "tandoor-recipes";
    port = mkOption {
      default = 14380;
      type = types.port;
    };
    domain = mkOption {
      default = "recipes.eyen.ca";
      type = types.str;
    };
    acme_host = mkOption {
      default = "eyen.ca";
      type = types.str;
    };
  };
  config =
    mkIf cfg.enable
    {
      my.nginx.enable = true;
      my.postgresql.enable = true;
      #sops.secrets."tandoor/db_password" = {};
      sops.secrets."tandoor/.env" = {
        format = "dotenv";
        sopsFile = ../secrets/tandoor.env;
        restartUnits = ["tandoor-recipes.service"];
      };
      services.tandoor-recipes = {
        inherit (cfg) port;
        enable = true;
        extraConfig = {
          FRACTION_PREF_DEFAULT = "1";
          ALLOWED_HOSTS = "${cfg.domain}";
        };
        #package =
        #  pkgs.tandoor-recipes.overrideAttrs (finalAttrs: previousAttrs: {
        #  });
      };

      systemd.services.tandoor-recipes = {
        serviceConfig.EnvironmentFile = [config.sops.secrets."tandoor/.env".path];
        environment.GUNICORN_CMD_ARGS = pkgs.lib.mkForce "--bind=${config.services.tandoor-recipes.address}:${toString config.services.tandoor-recipes.port} --access-logfile '-' --error-logfile '-'";
      };

      services.nginx.virtualHosts.${cfg.domain} = {
        useACMEHost = cfg.acme_host;
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${builtins.toString config.services.tandoor-recipes.port}";
        };
      };
      my.backups.services.tandoor-recipes = {
        paths = ["/var/lib/private/tandoor-recipes/recipes" "/var/lib/private/tandoor-recipes/recipes"];
        postgres_databases = ["tandoor_recipes"];
      };
      services.postgresql = {
        ensureDatabases = ["tandoor_recipes"];
        ensureUsers = [
          {
            name = "tandoor_recipes";
            ensureDBOwnership = true;
          }
        ];
      };
    };
}
