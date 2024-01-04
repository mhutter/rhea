{ config, lib, pkgs, ... }:

{
  imports = [
    ./filesystems.nix
    ./modules/boot.nix
    ./modules/networking.nix
    ./modules/persistence.nix
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

  modules.persistence = {
    dirs = [
      "/var/lib/tailscale"
      "/var/log"
    ];
  };

  time. timeZone = "UTC";

  users. mutableUsers = false;
  users.users.root = {
    openssh.authorizedKeys.keys = [ "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOPhRxDZsJ7zFb7Zz7vrRMmIvptWCfA2HgnxYnlmhu24 tera2024" ];
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

  # Tailscale
  services.tailscale = {
    enable = true;
    openFirewall = true;
    useRoutingFeatures = "server";
  };

  # persistence
  environment.etc."ssh/ssh_host_ed25519_key".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key";
  environment.etc."ssh/ssh_host_ed25519_key.pub".source = "/nix/persist/etc/ssh/ssh_host_ed25519_key.pub";
  environment.etc."machine-id".source = "/nix/persist/etc/machine-id";

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
