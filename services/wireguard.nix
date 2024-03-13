{ config, pkgs, ... }:

let
  serverPort = 45516;
  serverInterface = config.modules.networking.nic;

  ip4tables = "${pkgs.iptables}/bin/iptables";
  ip6tables = "${pkgs.iptables}/bin/ip6tables";
  nat4Rule = "POSTROUTING -s 10.10.10.0/24 -o ${serverInterface} -j MASQUERADE";
  input4Rule = "INPUT -i wg0 -s 10.10.10.0/24 -j ACCEPT";
  nat6Rule = "POSTROUTING -s fd3f:3ca6:ffc1::1/64 -o ${serverInterface} -j MASQUERADE";
  input6Rule = "INPUT -i wg0 -s fd3f:3ca6:ffc1::1/64 -j ACCEPT";

in
{
  age.secrets.psk-tera.file = ../secrets/wg-psk-tera.age;

  networking = {
    nat = {
      enable = true;
      externalInterface = serverInterface;
      internalInterfaces = [ "wg0" ];
    };

    firewall.allowedUDPPorts = [ serverPort ];

    wireguard.interfaces.wg0 = {
      ips = [ "10.10.10.1/24" "fd3f:3ca6:ffc1::1/64" ];
      listenPort = serverPort;

      postSetup = [
        "${ip4tables} -t nat -I ${nat4Rule}"
        "${ip4tables} -t filter -I ${input4Rule}"
        "${ip6tables} -t nat -I ${nat6Rule}"
        "${ip6tables} -t filter -I ${input6Rule}"
      ];
      postShutdown = [
        "${ip4tables} -t nat -D ${nat4Rule}"
        "${ip4tables} -t filter -D ${input4Rule}"
        "${ip6tables} -t nat -D ${nat6Rule}"
        "${ip6tables} -t filter -D ${input6Rule}"
      ];

      privateKeyFile = "/nix/secret/wg0.key";
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
