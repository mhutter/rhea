{ lib, config, ... }:

let
  # Configuration
  domain = "feeds.mhnet.app";
  listenAddr = "127.0.0.1:4144";

in
{
  age.secrets.miniflux-env.file = ../secrets/miniflux-env.age;

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode gzip
    reverse_proxy ${listenAddr}
  '';

  services.miniflux = {
    enable = true;
    config = {
      LISTEN_ADDR = listenAddr;
      BASE_URL = "https://${domain}/";
      HTTPS = 1;

      CREATE_ADMIN = lib.mkForce 0;

      OAUTH2_PROVIDER = "oidc";
      OAUTH2_CLIENT_ID = "miniflux";
      # OAUTH2_CLIENT_SECRET
      OAUTH2_REDIRECT_URL = "https://${domain}/oauth2/oidc/callback";
      OAUTH2_OIDC_DISCOVERY_ENDPOINT = "https://id.mhnet.app/auth/v1";
      OAUTH2_USER_CREATION = 1;
    };
    # It's called "adminCredentials" but it's actually just chugged in the systemd service as `EnvironmentFile` :)
    adminCredentialsFile = config.age.secrets.miniflux-env.path;
  };
}
