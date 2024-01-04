{ config, lib, ... }:

let
  cfg = config.modules.networking;
in
{
  options.modules.networking = with lib; {
    hostName = mkOption {
      description = "System Hostname";
      type = types.str;
    };
    nic = mkOption {
      description = "Primary network interface";
      type = types.str;
    };
    nameservers = mkOption {
      description = "DNS resolvers";
      type = types.listOf types.str;
      default = [
        "1.1.1.1"
        "8.8.8.8"
        "2606:4700:4700::1111"
        "2001:4860:4860::8844"
      ];
    };

    # IPv4 Settings
    ipv4.address = mkOption {
      description = "IPv4 address";
      type = types.str;
    };
    ipv4.prefixLength = mkOption {
      description = "IPv4 prefix length";
      type = types.addCheck types.int (n: n >= 0 && n <= 32);
    };
    ipv4.netmask = mkOption {
      description = "IPv4 netmask";
      type = types.str;
    };
    ipv4.gateway = mkOption {
      description = "IPv4 default gateway";
      type = types.str;
    };

    # IPv6 Settings
    ipv6.address = mkOption {
      description = "IPv6 address";
      type = types.str;
    };
    ipv6.prefixLength = mkOption {
      description = "IPv6 prefix length";
      type = types.addCheck types.int (n: n >= 0 && n <= 128);
    };
    ipv6.gateway = mkOption {
      description = "IPv6 default gateway";
      type = types.str;
    };
  };

  config = {
    networking = {
      inherit (cfg) hostName nameservers;

      useDHCP = false;

      interfaces."${cfg.nic}" = {
        ipv4.addresses = [{ inherit (cfg.ipv4) address prefixLength; }];
        ipv6.addresses = [{ inherit (cfg.ipv6) address prefixLength; }];
      };

      defaultGateway = cfg.ipv4.gateway;
      defaultGateway6 = { address = cfg.ipv6.gateway; interface = cfg.nic; };
    };

    boot.kernelParams = [ "ip=${cfg.ipv4.address}::${cfg.ipv4.gateway}:${cfg.ipv4.netmask}:${cfg.hostName}:${cfg.nic}:off" ];
  };
}
