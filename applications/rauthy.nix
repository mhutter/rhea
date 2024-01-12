{ lib, config, ... }:

let
  dataDir = "/nix/persist/var/lib/rauthy";
  domain = "id.mhnet.app";
  port = "36013";

in
{
  age.secrets.rauthy.file = ../secrets/rauthy.age;

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    reverse_proxy 127.0.0.1:${port}
  '';

  virtualisation.oci-containers.containers.rauthy = {
    image = "ghcr.io/sebadob/rauthy:0.20.1-lite";
    ports = [ "127.0.0.1:${port}:${port}/tcp" ];
    autoStart = true;
    volumes = [
      "${dataDir}:/data:U"
      "${config.age.secrets.rauthy.path}:/app/rauthy.cfg:U,ro"
    ];

    # Reference: https://sebadob.github.io/rauthy/config/config.html
    environment = {
      ### Storage
      DATABASE_URL = "sqlite:/data/rauthy.db";

      ### Email
      EMAIL_SUB_PREFIX = "mhnet IAM";
      # In ../secrets/rauthy.age
      # SMTP_USERNAME
      # SMTP_PASSWORD
      # SMTP_URL
      # SMTP_FROM

      ### Encryption
      # In ../secrets/rauthy.age
      # ENC_KEYS
      # ENC_KEY_ACTIVE
      ARGON2_M_COST = "262144";
      ARGON2_T_COST = "6";
      ARGON2_P_COST = "48";

      ### Events/Audit
      # In ../secrets/rauthy.age
      # EVENT_EMAIL

      ### Server
      LISTEN_SCHEME = "http";
      LISTEN_PORT_HTTP = port;
      PUB_URL = domain;
      PROXY_MODE = "true";
      SWAGGER_UI_INTERNAL = "false";

      ### Webauthn
      RP_ID = domain;
      RP_ORIGIN = "https://${domain}:443";
      RP_NAME = "mhnet IAM";
    };
  };
}
