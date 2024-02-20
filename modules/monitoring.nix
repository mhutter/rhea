{ config, ... }:

let
  # Configuration
  grafanaDomain = "grafana.mhnet.app";

in
{
  services.caddy.virtualHosts."${grafanaDomain}".extraConfig = ''
    reverse_proxy 127.0.0.1:${toString config.services.grafana.settings.server.http_port}
  '';

  services.grafana = {
    enable = true;

    settings = {
      analytics.reporting_enabled = false;

      server = {
        http_addr = "127.0.0.1";
        http_port = 3000;
        root_url = "https://${grafanaDomain}/";
        enable_gzip = true;
      };
      security = {
        cookie_secure = true;
        cookie_samesite = "strict";
      };
    };

    provision = {
      enable = true;
      datasources.settings.datasources = [{
        name = "Loki";
        type = "loki";
        access = "proxy";
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
      }];
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      analytics.reporting_enabled = false;

      server.http_listen_port = 3100;
      memberlist.join_members = [ "rhea:7946" ];

      common = {
        replication_factor = 1;
        path_prefix = config.services.loki.dataDir;
        ring.kvstore.store = "inmemory";
      };

      schema_config.configs = [{
        from = "1970-01-01";
        store = "tsdb";
        object_store = "filesystem";
        schema = "v12";
        index = {
          prefix = "index_";
          period = "24h";
        };
      }];
    };
  };

  services.promtail = {
    enable = true;
    configuration = {
      server = {
        http_listen_port = 3031;
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}/loki/api/v1/push";
      }];
      scrape_configs = [{
        job_name = "journal";
        journal = {
          max_age = "12h";
          labels = {
            job = "systemd-journal";
            host = config.networking.hostName;
          };
        };
        relabel_configs = [{
          source_labels = [ "__journal__systemd_unit" ];
          target_label = "unit";
        }];
      }];
    };
  };

  modules.persistence.dirs = {
    "${config.services.loki.dataDir}" = { inherit (config.services.loki) user group; };
    "${config.services.grafana.dataDir}" = {
      user = config.systemd.services.grafana.serviceConfig.User;
    };
  };
}
