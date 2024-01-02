{ config, lib, pkgs, ... }:

{
  imports = [ ./hardware-configuration.nix ];

  boot.loader.grub = {
    enable = true;
    device = "/dev/nvme0n1";
    mirroredBoots = [
      {
        devices = [ "/dev/nvme1n1" ];
        path = "/boot-fallback";
      }
    ];
  };
  boot.initrd.network = {
    enable = true;
    ssh = {
      enable = true;
      port = 41083;
      # this is the default
      # authorizedKeys = config.users.users.root.openssh.authorizedKeys.keys;
      hostKeys = [ "/nix/secret/initrd/ssh_host_ed25519_key" ];
    };
  };

  networking.hostName = "rhea"; # Define your hostname.
  # set to `boot.swraid.mdadmConf` by default
  # environment.etc."mdadm.conf".text = ''
  #   HOMEHOST rhea
  # '';

  boot.swraid.enable = true;
  boot.swraid.mdadmConf = ''
    HOMEHOST rhea
  '';

  boot.kernelParams = [ "ip=116.202.233.38::116.202.233.1:255.255.255.192:rhea:enp35s0:off" ];
  networking = {
    useDHCP = false;
    interfaces."enp35s0" = {
      ipv4.addresses = [{ address = "116.202.233.38"; prefixLength = 26; }];
      ipv6.addresses = [{ address = "2a01:4f8:241:4c27::1"; prefixLength = 64; }];
    };
    defaultGateway = "116.202.233.1";
    defaultGateway6 = { address = "fe80::1"; interface = "enp35s0"; };
  };

  time.timeZone = "UTC";

  users.mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRFlkyW0MXxYjA1HUzJ18nlTLtXOHKV0rVJD/46v7Sb tera2023" ];
  };

  environment.systemPackages = with pkgs; [ vim wget ];

  services.openssh = {
    enable = true;
    ports = [ 6272 ];
    settings.PermitRootLogin = "prohibit-password";
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ ] ++ config.services.openssh.ports;
  system.stateVersion = "24.05"; # Did you read the comment?

  # persistence
  environment.etc."ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";

  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";
}
