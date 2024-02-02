{ config, ... }:

let
  # Configuration
  domain = "dms.mhnet.app";
  port = toString config.services.docspell-restserver.bind.port;

  jdbc = {
    url = "jdbc:postgresql://localhost:5432/docspell";
    user = "docspell";
  };

  envFile = config.age.secrets.docspell-env.path;
  extraServiceConfig = {
    # https://github.com/lightbend/config?tab=readme-ov-file#optional-system-or-env-variable-overrides
    Environment = "JAVA_OPTS=-Dconfig.override_with_env_vars=true";
    EnvironmentFile = envFile;
    Restart = "always";
  };

in
{
  age.secrets.docspell-env.file = ../secrets/docspell-env.age;

  # Set extra environment variables for credentials
  systemd.services.docspell-restserver.serviceConfig = extraServiceConfig;
  systemd.services.docspell-joex.serviceConfig = extraServiceConfig;

  services.caddy.virtualHosts."${domain}".extraConfig = ''
    encode gzip
    reverse_proxy 127.0.0.1:${port} {
      header_up X-Real-IP {remote_host}
    }
  '';

  services.docspell-restserver = {
    enable = true;
    app-name = "mhnet Docspell";
    base-url = "https://${domain}";

    backend = {
      inherit jdbc;
      signup.mode = "open";
    };

    full-text-search = {
      enabled = true;
      backend = "postgresql";
      postgresql.use-default-connection = true;
    };

    # The whole OpenID configuration is set via env vars.
    # 
    # Unfortunately, setting Client ID and Secret via Env vars is not supported
    # by Docspell. Now the config library has a way to force-overwrite certain
    # configurations, but when using this features with arrays (as `openid` is)
    # means you have to redefine the _whole_ item.
    # openid = {};
  };

  services.docspell-joex = {
    enable = true;

    inherit jdbc;

    scheduler.pool-size = 8;
  };
}
