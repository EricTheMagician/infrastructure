{
  stdenv,
  lib,
  postgresql,
  dpkg,
  fetchurl,
  ...
}: let
  pname = "pgvecto.rs";
  version = "0.1.11";
  hashes = {
    "16" = "sha256-L+57VRFv4rIEjvqExFvU5C9XI7l0zWj9pkKvNE5DP+k=";
  };
  major = "16"; # lib.versions.major postgresql.version;
in
  stdenv.mkDerivation {
    inherit pname version;

    buildInputs = [dpkg];

    src = fetchurl {
      #url = "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}_${version}_amd64.deb";
      url = "https://github.com/tensorchord/pgvecto.rs/releases/download/v${version}/vectors-pg${major}-v${version}-x86_64-unknown-linux-gnu.deb";
      # https://github.com/tensorchord/pgvecto.rs/releases/download/v0.1.13/vectors-pg16_0.1.13_amd64.deb
      hash = hashes."${major}";
    };

    dontUnpack = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      mkdir -p $out
      dpkg -x $src $out
      install -D -t $out/lib $out/usr/lib/postgresql/${major}/lib/*.so
      install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.sql
      install -D -t $out/share/postgresql/extension $out/usr/share/postgresql/${major}/extension/*.control
      rm -rf $out/usr
    '';

    meta = {
      description = "Scalable Vector database plugin for Postgres, written in Rust, specifically designed for LLM";
      homepage = "https://github.com/tensorchord/pgvecto.rs";
      license = lib.licenses.asl20;
      inherit (postgresql.meta) platforms;
    };
  }
## packages/pgvecto-rs.nix
##
## Author: Eric Yen
## URL:    https://github.com/EricTheMagician/infrastructure
##
## A PostgreSQL extension needed for Immich.
#{
#  lib,
#  rustPlatform,
#  buildPgrxExtension,
#  fetchFromGitHub,
#  clang_16,
#  llvmPackages_16,
#  postgresql_16,
#  cargo-pgrx,
#  rust,
#  fetchCrate,
#}: let
#  postgresql = postgresql_16;
#  cargo-pgrx_0_11_0 = cargo-pgrx.overrideAttrs (old: rec {
#    version = "0.11.0";
#    name = "cargo-pgrx-${version}";
#    src = fetchCrate {
#      pname = "cargo-pgrx";
#      inherit version;
#      hash = "sha256-GiUjsSqnrUNgiT/d3b8uK9BV7cHFvaDoq6cUGRwPigM=";
#    };
#    cargoDeps = old.cargoDeps.overrideAttrs (_: {
#      inherit src;
#      outputHash = "sha256-oXOPpK8VWzbFE1xHBQYyM5+YP/pRdLvTVN/fjxrgD/c=";
#    });
#  });
#in
#  rustPlatform.buildRustPackage rec {
#    #(buildPgrxExtension.override {cargo-pgrx = cargo-pgrx_0_11_0;}) rec {
#    inherit postgresql;
#    pname = "pgvecto.rs";
#    version = "0.1.13";
#    doCheck = false;
#    nativeBuildInputs = [postgresql_16 clang_16 cargo-pgrx_0_11_0 llvmPackages_16.clang-unwrapped.lib llvmPackages_16.clang-unwrapped];
#    src = fetchFromGitHub {
#      owner = "tensorchord";
#      repo = pname;
#      rev = "v${version}";
#      sha256 = "sha256-l9bT8CppNv18S4jqVAdA1IujqBHaLwdFisq+dhZQaaM="; #13
#      #sha256 = "sha256-oJyCUJV3GxGIXAXqY0vp0PZ3QKj3JK54+khtGAn0S6o="; # 12
#    };
#    # precheck inspired form cargo-pgrx
#    pgrxPostgresMajor = lib.versions.major postgresql.version;
#    LIBCLANG_PATH = "${llvmPackages_16.clang-unwrapped.lib}/lib";
#    preBuild = ''
#      #   export RUST_SRC_PATH="${rust.packages.stable.rustPlatform.rustLibSrc}";
#         export PGRX_HOME=$(mktemp -d)
#         export PGDATA="$PGRX_HOME/data-16/"
#         export LIBCLANG_PATH="${llvmPackages_16.clang-unwrapped.lib}/lib";
#         cargo-pgrx pgrx init "--pg16=${postgresql_16}/bin/pg_config"
#         echo "unix_socket_directories = '$(mktemp -d)'" > "$PGDATA/postgresql.conf"
#         ## This is primarily for Mac or other Nix systems that don't use the nixbld user.
#         export USER="$(whoami)"
#         pg_ctl start
#         createuser -h localhost --superuser --createdb "$USER" || true
#         pg_ctl stop
#    '';
#    patches = [./fix-path.patch];
#    cargoLock = {
#      lockFile = src + "/Cargo.lock";
#      outputHashes = {
#        "openai_api_rust-0.1.8" = "sha256-os5Y8KIWXJEYEcNzzT57wFPpEXdZ2Uy9W3j5+hJhhR4=";
#        "pgrx-0.11.0" = "sha256-TxFv989AViH6Rspa515k2+lAE8t7B8OWysRWjlaQhbA=";
#        "std_detect-0.1.5" = "sha256-RwWejfqyGOaeU9zWM4fbb/hiO1wMpxYPKEjLO0rtRmU=";
#      };
#    };
#    #cargoDeps = rustPlatform.importCargoLock {
#    #  lockFile = ./Cargo.lock;
#    #  outputHashes = {
#    #  };
#    #};
#  }

