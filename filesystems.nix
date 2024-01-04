{
  fileSystems."/" = {
    device = "none";
    fsType = "tmpfs";
    options = [ "defaults" "size=2G" "mode=0755" ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot0";
    fsType = "ext4";
  };

  fileSystems."/boot-fallback" = {
    device = "/dev/disk/by-label/boot1";
    fsType = "ext4";
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nix";
    fsType = "ext4";
  };
}
