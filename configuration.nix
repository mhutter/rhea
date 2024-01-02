{ config, lib, pkgs, ... }:

let
  # Network settings
  hostname = "rhea";
  nic = "enp35s0";
  ipv4 = {
    address = "116.202.233.38";
    gateway = "116.202.233.1";
    prefixLength = 26;
    netmask = "255.255.255.192";
  };
  ipv6 = {
    address = "2a01:4f8:241:4c27::1";
    prefixLength = 64;
    gateway = "fe80::1";
  };
in
{
  imports = [
    ./hardware-configuration.nix
  ];

  boot = (import ./boot.nix) { inherit config ipv4 nic; };
  networking = (import ./networking.nix) {
    inherit config ipv4 ipv6 hostname nic;
  };

  time. timeZone = "UTC";

  users. mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILRFlkyW0MXxYjA1HUzJ18nlTLtXOHKV0rVJD/46v7Sb tera2023" ];
  };

  environment.systemPackages = with pkgs; [
    htop
    tmux
    vim
  ];

  services.openssh = {
    enable = true;
    ports = [ 6272 ];
    settings.PermitRootLogin = "prohibit-password";
    # prevent RSA host key from happening
    hostKeys = [{
      path = "/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }];
  };

  # persistence
  environment.etc."ssh/ssh_host_rsa_key".source = "/nix/persist/etc/ssh/ssh_host_rsa_key";
  environment.etc."ssh/ssh_host_rsa_key.pub".source = "/nix/persist/etc/ssh/ssh_host_rsa_key.pub";
  environment.etc."ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";

  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";

  system.stateVersion = "24.05"; # Did you read the comment?
}
