{ config, pkgs, ... }:

let
  serverPort = 45516;
  serverInterface = config.modules.networking.nic;
  wgNic = "wg0";

  ip4tables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
  nat4Rule = "POSTROUTING -s 10.10.10.0/24 -o ${serverInterface} -j MASQUERADE";
  nat6Rule = "POSTROUTING -s fd3f:3ca6:ffc1::1/64 -o ${serverInterface} -j MASQUERADE";

in
{
  age.secrets.psk-tera.file = ../secrets/wg-psk-tera.age;

  networking = {
    nat = {
      enable = true;
      externalInterface = serverInterface;
      internalInterfaces = [ wgNic ];
    };

    firewall.allowedUDPPorts = [ serverPort ];
    firewall.trustedInterfaces = [ wgNic ];

    wireguard.interfaces."${wgNic}" = {
      ips = [ "10.10.10.1/24" "fd3f:3ca6:ffc1::1/64" ];
      listenPort = serverPort;

      postSetup = [
        "${ip4tables} -t nat -I ${nat4Rule}"
        "${ip6tables} -t nat -I ${nat6Rule}"
      ];
      postShutdown = [
        "${ip4tables} -t nat -D ${nat4Rule}"
        "${ip6tables} -t nat -D ${nat6Rule}"
      ];

      privateKeyFile = "/nix/secret/${wgNic}.key";
      generatePrivateKeyFile = true;

      peers = [{
        # tera
        allowedIPs = [ "10.10.10.2" "fd3f:3ca6:ffc1::2" ];
        publicKey = "G4qoH5OSR9Q1FtKdValyYEyKvR/hWxNAeAa33e4RMFU=";
        presharedKeyFile = config.age.secrets.psk-tera.path;
      }];
    };
  };
}
