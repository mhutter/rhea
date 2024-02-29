{ config, pkgs, ... }:

let
  # Configuration
  grafanaDomain = "grafana.mhnet.app";

  # Helpers
  gss = config.services.grafana.settings.server;
  cfgGrafanaAddr = "${gss.http_addr}:${toString gss.http_port}";
  lss = config.services.loki.configuration.server;
  cfgLokiAddr = "${lss.http_listen_address}:${toString lss.http_listen_port}";
  cfgVickyAddr = config.services.victoriametrics.listenAddress;

in
{
  services.caddy.virtualHosts."${grafanaDomain}".extraConfig = ''
    reverse_proxy ${cfgGrafanaAddr}
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
      datasources.settings.datasources = [
        {
          name = "Loki";
          type = "loki";
          access = "proxy";
          url = "http://${cfgLokiAddr}";
        }
        {
          name = "VictoriaMetrics";
          type = "prometheus";
          access = "proxy";
          url = "http://${cfgVickyAddr}";
          isDefault = true;
        }
      ];
    };
  };

  services.loki = {
    enable = true;
    configuration = {
      auth_enabled = false;
      analytics.reporting_enabled = false;

      server = {
        http_listen_address = "127.0.0.1";
        http_listen_port = 3100;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 9095;
        log_level = "warn";
      };
      memberlist.join_members = [ "rhea:7946" ];

      common = {
        instance_addr = "127.0.0.1";
        path_prefix = config.services.loki.dataDir;
        replication_factor = 1;
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
        http_listen_address = "127.0.0.1";
        http_listen_port = 3031;
        grpc_listen_address = "127.0.0.1";
        grpc_listen_port = 0;
      };
      positions = {
        filename = "/tmp/positions.yaml";
      };
      clients = [{
        url = "http://${cfgLokiAddr}/loki/api/v1/push";
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

  services.caddy.virtualHosts."victoriametrics.mhnet.app".extraConfig = ''
    reverse_proxy ${cfgVickyAddr}
    basicauth {
      mh $2a$14$aDHvtUSsdfIQXab8FpZGduzxcjAwAR.maIMOUeIstCpInVyBbLAJi
    }
  '';
  services.victoriametrics = {
    enable = true;
    listenAddress = "127.0.0.1:8428";
    retentionPeriod = 12; # months; must be a number
    # storageDataPath is hardcoded to /var/lib/victoriametrics
    extraOptions = [
      "-promscrape.config=${pkgs.writeText "scrape.yml" ''
global:
  scrape_interval: 15s

scrape_configs:
  - job_name: grafana
    static_configs:
      - targets:
          - http://${cfgGrafanaAddr}/metrics
  - job_name: loki
    static_configs:
      - targets:
          - http://${cfgLokiAddr}/metrics
  - job_name: caddy
    static_configs:
      - targets:
          - http://127.0.0.1:2019/metrics
  - job_name: victoriametrics
    static_configs:
      - targets:
          - http://${cfgVickyAddr}/metrics
''}"
    ];
  };

  modules.persistence.dirs = {
    "/var/lib/private/victoriametrics" = { };
    "${config.services.loki.dataDir}" = { inherit (config.services.loki) user group; };
    "${config.services.grafana.dataDir}" = {
      user = config.systemd.services.grafana.serviceConfig.User;
    };
  };
}
