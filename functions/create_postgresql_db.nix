# This module was taken from keycloak and adapted, but I think this is overkill for me
# It's useful for creating network accessed databases
{
  name, # database name
  user_name, # username for the database
  passwordFile, # path to the password file
  beforeServices ? [], # the service that
  wantedBy,
  config,
  lib,
  backupDB ? true,
  ...
}: {
  systemd.services."${name}PostgreSQLInit" = {
    after = ["postgresql.service"];
    before = beforeServices;
    inherit wantedBy;
    bindsTo = ["postgresql.service"];
    path = [config.services.postgresql.package];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "postgres";
      Group = "postgres";
      LoadCredential = ["db_password:${passwordFile}"];
    };
    script = ''
      set -o errexit -o pipefail -o nounset -o errtrace
      shopt -s inherit_errexit

      create_role="$(mktemp)"
      trap 'rm -f "$create_role"' EXIT

      # Read the password from the credentials directory and
      # escape any single quotes by adding additional single
      # quotes after them, following the rules laid out here:
      # https://www.postgresql.org/docs/current/sql-syntax-lexical.html#SQL-SYNTAX-CONSTANTS
      db_password="$(<"$CREDENTIALS_DIRECTORY/db_password")"
      db_password="''${db_password//\'/\'\'}"

      echo "CREATE ROLE ${user_name} WITH LOGIN PASSWORD '$db_password' CREATEDB" > "$create_role"
      psql -tAc "SELECT 1 FROM pg_roles WHERE rolname='${user_name}'" | grep -q 1 || psql -tA --file="$create_role"
      psql -tAc "SELECT 1 FROM pg_database WHERE datname = '${user_name}'" | grep -q 1 || psql -tAc 'CREATE DATABASE "${name}" OWNER "${user_name}"'
    '';
  };
  services.postgresqlBackup.databases = lib.optional backupDB name;
}
