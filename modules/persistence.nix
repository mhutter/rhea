{ config, lib, ... }:
let
  cfg = config.modules.persistence;
in
{
  options.modules.persistence = with lib; {
    dirs = mkOption {
      description = "Directoies that need persistence";
      type = types.listOf types.str;
      default = [ ];
    };
  };

  config = {
    fileSystems = builtins.listToAttrs (map
      (dir: {
        name = dir;
        value = {
          device = "/nix/persist${dir}";
          fsType = "none";
          options = [ "bind" ];
        };
      })
      cfg.dirs);
  };
}
