{ config, ... }:
let
  domain = "iam.mhnet.app";
  port = 59875;
in
{
  age.secrets.keycloak-db-pw.file = ../secrets/keycloak-db-pw.age;

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    reverse_proxy [::1]:${toString port}
  '';

  services.keycloak = {
    enable = true;
    database = {
      createLocally = true;
      passwordFile = config.age.secrets.keycloak-db-pw.path;
    };
    settings = {
      hostname = domain;
      hostname-strict-backchannel = true;

      http-port = port;
      http-host = "::1";

      proxy = "edge";
    };
  };
}
