{ lib, config, ... }:

let
  cfg = config.modules.persistence;

  # Helper functions

  # Define a string option with the given default value
  mkStrOption = default: lib.mkOption { inherit default; type = lib.types.str; };

  # Determine the source directory of the given dir
  src = dir: toString (cfg.root + dir);

in
{
  options.modules.persistence = with lib; {
    root = mkOption {
      description = "Directory where the data will be persisted";
      type = types.str;
      default = "/nix/persist";
    };

    dirs = mkOption {
      type = types.attrsOf
        (types.submodule
          ({ name, ... }: {
            options = {
              dir = mkStrOption name;
              user = mkStrOption "root";
              group = mkStrOption "root";
              mode = mkStrOption "0700";
            };
          }));
      default = { };
    };
  };

  config = {
    # Ensure required directories exist and have proper owners & permissions
    systemd.tmpfiles.settings."10-persistence" = lib.listToAttrs (map
      ({ dir, user, group, mode, ... }: {
        name = src dir;
        value.d = { inherit user group mode; };
      })
      (lib.attrValues cfg.dirs));

    # Mount directories to their targets
    fileSystems = lib.mapAttrs
      (name: { dir, ... }: {
        device = src dir;
        fsType = "none";
        options = [ "bind" "noexec" ];
      })
      cfg.dirs;
  };
}
