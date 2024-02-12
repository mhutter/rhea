{ ... }:
{
  modules.persistence.dirs."/var/lib/containers" = {
    noexec = false;
  };

  virtualisation.podman.autoPrune = {
    # Automatically remove unused images (and other stuff) once a week
    enable = true;
    flags = [ "--all" ];
  };
}
