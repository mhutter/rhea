{ ... }:
{
  # Cache images locally
  modules.persistence.dirs = [
    # SQLite DB containing layer locations
    "/var/lib/containers/cache"
    # Image metadata
    "/var/lib/containers/storage/overlay-images"
    # Image layers
    "/var/lib/containers/storage/overlay-layers"
  ];

  virtualisation.podman.autoPrune = {
    # Automatically remove unused images (and other stuff) once a week
    enable = true;
    flags = [ "--all" ];
  };
}
