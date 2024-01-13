{ lib, config, ... }:

let
  # Configuration
  domain = "pw.mhnet.app";
  port = "42367";

in
{
  age.secrets.vaultwarden.file = ../secrets/vaultwarden.age;

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode gzip
    reverse_proxy 127.0.0.1:${port} {
      header_up X-Real-IP {remote_host}
    }
  '';

  modules.persistence.dirs."/var/lib/bitwarden_rs" = {
    user = "vaultwarden";
    group = "vaultwarden";
  };

  services.vaultwarden = {
    enable = true;

    environmentFile = config.age.secrets.vaultwarden.path;
    config = {
      # Network
      DOMAIN = "https://${domain}";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = port;

      ### Email
      SMTP_FROM = "pw@mhnet.dev";
      SMTP_FROM_NAME = "mhnet Vaultwarden";
      # in ../secrets/vaultwarden.age
      # SMTP_HOST
      # SMTP_PORT
      # SMTP_SECURITY
      # SMTP_USERNAME
      # SMTP_PASSWORD
    };
  };
}
