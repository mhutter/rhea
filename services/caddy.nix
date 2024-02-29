{ lib, config, ... }:

{
  services.caddy = {
    enable = true;
    globalConfig = ''
      servers {
        metrics
      }
    '';
  };

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  modules.persistence.dirs."${config.services.caddy.dataDir}" = {
    user = "caddy";
    group = "caddy";
  };
}
