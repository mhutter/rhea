{ lib, config, ... }:

{
  services.caddy = {
    enable = true;
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  modules.persistence.dirs = [ config.services.caddy.dataDir ];
}
