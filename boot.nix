{ config, ipv4, nic, ... }:

{
  kernelParams = [ "ip=${ipv4.address}::${ipv4.gateway}:${ipv4.netmask}:${config.networking.hostName}:${nic}:off" ];
  kernelModules = [ "kvm-amd" ];
  extraModulePackages = [ ];

  initrd = {
    availableKernelModules = [
      "aesni_intel"
      "ahci"
      "cryptd"
      "igb"
      "nvme"
    ];
    kernelModules = [ ];

    luks.devices."cryptroot".device = "/dev/md0";

    network = {
      enable = true;
      ssh = {
        enable = true;
        port = 41083;
        # this is the default
        # authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
        hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
      };
    };
  };

  loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    mirroredBoots = [
      {
        devices = [ "/dev/nvme1n1" ];
        path = "/boot-fallback";
      }
    ];
  };

  swraid.enable = true;
  swraid.mdadmConf = ''
    HOMEHOST ${config.networking.hostName}
  '';
}
