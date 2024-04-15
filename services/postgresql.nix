{ config, lib, ... }:

let
  createRepackExtensions = lib.strings.concatMapStringsSep "\n"
    (db: "psql -d ${db} -c 'CREATE EXTENSION IF NOT EXISTS pg_repack'")
    config.services.postgresql.ensureDatabases;

  dataDir = "/nix/persist/var/lib/postgresql/${config.services.postgresql.package.psqlSchema}";

in
{
  # Some services can only connect via TCP (fuck you, JDBC) and hence need a
  # password; those are set in this init script
  age.secrets.postgresql-init = {
    file = ../secrets/postgresql-init.age;
    owner = "postgres";
  };

  # This caused a race condition where postgresql would start up before the
  # data dir was ready (or systemd would create its own state dir), so instead
  # we just use the persisted folder and manage it ourselves (see below)
  # modules.persistence.dirs."${config.services.postgresql.dataDir}" = { };

  services.postgresql = {
    inherit dataDir;
    enable = true;
    extraPlugins = ps: with ps; [ pg_repack ];
    # TODO: ensure pg_repack runs regulary
    ensureDatabases = [
      "docspell"
    ];
    ensureUsers = [{ name = "docspell"; ensureDBOwnership = true; }];
  };

  # Systemd unit overrides
  systemd.services.postgresql = {
    # This will be APPENDED to the existing ExecPostStart script
    postStart = ''
      psql -f ${config.age.secrets.postgresql-init.path}
      ${createRepackExtensions}
    '';
  };

  # Create data dir
  systemd.tmpfiles.settings."10-persistence"."${dataDir}".d = {
    user = "postgres";
    group = "postgres";
    mode = "0700";
  };
}
