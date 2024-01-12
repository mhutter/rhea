{ config, lib, pkgs, ... }:

{
  imports = [
    # Own modules
    ./modules/boot.nix
    ./modules/filesystems.nix
    ./modules/networking.nix
    ./modules/persistence.nix

    # Services
    ./services/caddy.nix
    ./services/podman.nix
    ./services/sshd.nix
    ./services/tailscale.nix

    # Applications
    ./applications/rauthy.nix
    ./applications/vaultwarden.nix
  ];

  modules.networking = {
    hostName = "rhea";
    nic = "enp35s0";
    ipv4 = {
      address = "116.202.233.38";
      prefixLength = 26;
      netmask = "255.255.255.192";
      gateway = "116.202.233.1";
    };
    ipv6 = {
      address = "2a01:4f8:241:4c27::1";
      prefixLength = 64;
      gateway = "fe80::1";
    };
  };


  time. timeZone = "UTC";

  users. mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPhRxDZsJ7zFb7Zz7vrRMmIvptWCfA2HgnxYnlmhu24 tera2024" ];
  };

  environment.systemPackages = with pkgs; [
    htop
    tmux
  ];

  # Persistence
  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";
  modules.persistence.dirs = [ "/var/log" ];

  nix.settings = {
    auto-optimise-store = true;
    allowed-users = [ "root" ];
  };
  nix.extraOptions = ''
    experimental-features = nix-command flakes
  '';

  system.stateVersion = "24.05"; # Did you read the comment?

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.enableRedistributableFirmware = lib.mkDefault true;
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
