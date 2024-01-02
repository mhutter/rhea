{ config
, hostname
, ipv4
, ipv6
, nic
, ...
}:

{
  hostName = hostname;

  useDHCP = false;

  interfaces."${nic}" = {
    ipv4.addresses = [{ address = ipv4.address; prefixLength = ipv4.prefixLength; }];
    ipv6.addresses = [{ address = ipv6.address; prefixLength = ipv6.prefixLength; }];
  };

  defaultGateway = ipv4.gateway;
  defaultGateway6 = { address = ipv6.gateway; interface = nic; };

  nameservers = [
    "1.1.1.1"
    "8.8.8.8"
    "2606:4700:4700::1111"
    "2001:4860:4860::8844"
  ];

  firewall.allowedTCPPorts = [ ] ++ config.services.openssh.ports;
}
