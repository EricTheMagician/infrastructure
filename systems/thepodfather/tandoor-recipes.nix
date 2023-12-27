{
  config,
  pkgs,
  ...
}: let
  create_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "tandoor_recipes";
      user_name = "tandoor_recipes";
      passwordFile = config.sops.secrets."tandoor/db_password".path;
      wantedBy = ["tandoor-recipes.service"];
      inherit config;
      inherit (pkgs) lib;
    };
  inherit (pkgs.lib) mkMerge;
in
  mkMerge [
    create_database
    {
      sops.secrets."tandoor/db_password" = {};
      sops.secrets."tandoor/.env" = {
        format = "dotenv";
        sopsFile = ../../secrets/thepodfather/tandoor.env;
        restartUnits = ["tandoor-recipes.service"];
      };
      services.tandoor-recipes = {
        enable = true;
        port = 14380;
        extraConfig = {
          #DEBUG = "1";
          #DEBUG_TOOLBAR = "0";
          FRACTION_PREF_DEFAULT = "1";
          ALLOWED_HOSTS = "recipes.eyen.ca";
        };
        package =
          pkgs.tandoor-recipes.overrideAttrs (finalAttrs: previousAttrs: {
          });
      };

      systemd.services.tandoor-recipes = {
        serviceConfig.EnvironmentFile = [config.sops.secrets."tandoor/.env".path];
        environment.GUNICORN_CMD_ARGS = pkgs.lib.mkForce "--bind=${config.services.tandoor-recipes.address}:${toString config.services.tandoor-recipes.port} --access-logfile '-' --error-logfile '-'";
      };

      services.nginx.virtualHosts."recipes.eyen.ca" = {
        useACMEHost = "eyen.ca";
        forceSSL = true;
        locations."/" = {
          proxyPass = "http://localhost:${builtins.toString config.services.tandoor-recipes.port}";
        };
      };
      my.backup_paths = ["/var/lib/tandoor-recipes/recipes"];
    }
  ]
