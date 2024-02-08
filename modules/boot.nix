{ config, ... }:

let
  hostKeyDir = "${config.modules.persistence.root}/initrd";

in
{
  boot = {
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
          hostKeys = [ "${hostKeyDir}/ssh_host_ed25519_key" ];
        };
      };
    };

    loader.grub = {
      enable = true;
      device = "/dev/nvme0n1";
      mirroredBoots = [{
        devices = [ "/dev/nvme1n1" ];
        path = "/boot-fallback";
      }];
    };

    swraid.enable = true;
    swraid.mdadmConf = ''
      HOMEHOST ${config.networking.hostName}
    '';
  };

  # Ensure host keys are properly secured
  systemd.tmpfiles.settings."10-persistence"."${hostKeyDir}".d = {
    user = "root";
    group = "root";
    mode = "0700";
  };
}
