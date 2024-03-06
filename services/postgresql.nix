{ config, lib, ... }:

let
  createRepackExtensions = lib.strings.concatMapStringsSep "\n"
    (db: "psql -d ${db} -c 'CREATE EXTENSION IF NOT EXISTS pg_repack'")
    config.services.postgresql.ensureDatabases;

in
{
  # Some services can only connect via TCP (fuck you, JDBC) and hence need a
  # password; those are set in this init script
  age.secrets.postgresql-init = {
    file = ../secrets/postgresql-init.age;
    owner = "postgres";
  };

  modules.persistence.dirs."${config.services.postgresql.dataDir}" = { };

  services.postgresql = {
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

    # Try to prevent "Permission denied" when NixOS config changes are deployed
    partOf = [ "systemd-tmpfiles-resetup.service" ];
  };
}
