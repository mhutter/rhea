{ config, ... }:

let
  cfg = config.modules.backup;
  secrets = config.age.secrets;

in
{
  age.secrets.restic-env.file = ../secrets/restic-env.age;
  age.secrets.restic-password.file = ../secrets/restic-repository.age;
  age.secrets.restic-repository.file = ../secrets/restic-repository.age;

  services.restic.backups.local = {
    initialize = true;

    paths = [ config.modules.persistence.root ];

    repositoryFile = secrets.restic-repository.path;
    passwordFile = secrets.restic-password.path;
    environmentFile = secrets.restic-env.path;

    timerConfig = { OnCalendar = "hourly"; };
    extraBackupArgs = [
      "--compression=max"
      "--exclude-caches" # Ignore files in folers containing a CACHEDIR.TAG file
      "--no-scan" # We don't need a progress report
      "--one-file-system" # Don't traverse FS boundaries
    ];
    pruneOpts = [
      "--keep-hourly=24"
      "--keep-daily=7"
      "--keep-weekly=4"
      "--keep-monthly=12"
      "--keep-yearly=10"
    ];
  };
}
