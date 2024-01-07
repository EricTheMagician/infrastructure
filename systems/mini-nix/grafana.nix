{
  config,
  lib,
  ...
}: let
  create_database =
    import ../../functions/create_postgresql_db.nix
    {
      name = "grafana";
      user_name = "grafana";
      passwordFile = config.sops.secrets."grafana/db_password".path;
      wantedBy = ["grafana.service"];
      inherit config;
      inherit lib;
    };

  inherit (lib) mkMerge mkEnableOption mkIf;
  cfg = config.my.programs.grafana;
  grafana_secret_config = {
    sopsFile = ../../secrets/grafana.yaml;
    owner = "grafana";
    inherit (config.users.users.grafana) group;
  };
in {
  options = {
    my.programs.grafana = {
      enable = mkEnableOption "grafana";
    };
  };
  config = mkMerge [
    (
      mkIf cfg.enable {
        sops.secrets = {
          "grafana/secret_key" = grafana_secret_config;
          "grafana/db_password" = grafana_secret_config;
          "grafana/ldap.toml" = grafana_secret_config // {restartUnits = ["grafana.service"];};
        };
        services.grafana = mkIf cfg.enable {
          enable = true;

          settings = {
            database = {
              host = "/run/postgresql";
              user = "grafana";
              name = "grafana";
              type = "postgres";
              # Uses peer auth for local users, so we don't need a password.
              # Here's the syntax anyway for future refence:
              # password = "$__file{/run/secrets/homeassistant/dbpass}";
            };

            security = {
              secret_key = "$__file{${config.sops.secrets."grafana/secret_key".path}}";
              disable_initial_admin_creation = true; # uses ldap
            };

            server = {
              http_addr = "127.0.0.1";
              http_port = 58373;
              domain = "grafana.eyen.ca";
              #router_logging = cfg.debugLog;
            };

            "auth.ldap" = {
              # Set to `true` to enable LDAP integration (default: `false`)
              enabled = true;

              # Path to the LDAP specific configuration file (default: `/etc/grafana/ldap.toml`)
              config_file = config.sops.secrets."grafana/ldap.toml".path;

              # Allow sign-up should be `true` (default) to allow Grafana to create users on successful LDAP authentication.
              # If set to `false` only already existing Grafana users will be able to login.
              allow_sign_up = true;
            };
            #smtp = lib.mkIf (!(isNull cfg.smtp)) {
            #enabled = true;
            #inherit (cfg.smtp) from_address from_name;
            #host = "${cfg.smtp.host}:${toString cfg.smtp.port}";
            #user = cfg.smtp.username;
            #password = "$__file{${cfg.smtp.passwordFile}}";
            #};
          };
        };

        services.nginx = {
          virtualHosts."grafana.eyen.ca" = {
            forceSSL = true;
            useACMEHost = "eyen.ca";
            locations."/" = {
              proxyPass = "http://${toString config.services.grafana.settings.server.http_addr}:${toString config.services.grafana.settings.server.http_port}";
              proxyWebsockets = true;
            };
          };
        };
      }
    )
    {
      services.grafana.provision = mkIf cfg.enable {
        #dashboards.settings = lib.mkIf cfg.provisionDashboards {
        #  apiVersion = 1;
        #  providers = [
        #    {
        #      folder = "NixOS Self Host Blocks";
        #      options.path = ./monitoring/dashboards;
        #      allowUiUpdates = true;
        #      disableDeletion = true;
        #    }
        #  ];
        #};
        datasources.settings = {
          apiVersion = 1;
          datasources = [
            {
              orgId = 1;
              name = "Prometheus";
              type = "prometheus";
              url = "http://127.0.0.1:${toString config.services.prometheus.port}";
              uid = "df80f9f5-97d7-4112-91d8-72f523a02b09";
              isDefault = true;
              version = 1;
            }
            {
              orgId = 1;
              name = "Loki";
              type = "loki";
              url = "http://127.0.0.1:${toString config.services.loki.configuration.server.http_listen_port}";
              uid = "cd6cc53e-840c-484d-85f7-96fede324006";
              version = 1;
            }
          ];
          deleteDatasources = [
            {
              orgId = 1;
              name = "Prometheus";
            }
            {
              orgId = 1;
              name = "Loki";
            }
          ];
        };
        #alerting.contactPoints.settings = {
        #  apiVersion = 1;
        #  contactPoints = [
        #    {
        #      orgId = 1;
        #      receivers = lib.optionals ((builtins.length cfg.contactPoints) > 0) [
        #        {
        #          uid = "sysadmin";
        #          type = "email";
        #          settings.addresses = lib.concatStringsSep ";" cfg.contactPoints;
        #        }
        #      ];
        #    }
        #  ];
        #};
        alerting.policies.settings = {
          apiVersion = 1;
          policies = [
            {
              orgId = 1;
              receiver = "grafana-default-email";
              group_by = ["grafana_folder" "alertname"];
              group_wait = "30s";
              group_interval = "5m";
              repeat_interval = "4h";
            }
          ];
          # resetPolicies seems to happen after setting the above policies, effectively rolling back
          # any updates.
        };
        #alerting.rules.settings = let
        #  rules = builtins.fromJSON (builtins.readFile ./monitoring/rules.json);
        #  ruleIds = map (r: r.uid) rules;
        #in {
        #  apiVersion = 1;
        #  groups = [
        #    {
        #      orgId = 1;
        #      name = "SysAdmin";
        #      folder = "Self Host Blocks";
        #      interval = "10m";
        #      inherit rules;
        #    }
        #  ];
        #  # deleteRules seems to happen after creating the above rules, effectively rolling back
        #  # any updates.
        #};
      };

      services.prometheus = {
        enable = true;
        port = 33693;
      };

      services.loki = {
        enable = true;
        dataDir = "/var/lib/loki";
        configuration = {
          auth_enabled = false;

          server.http_listen_port = 35902;

          ingester = {
            lifecycler = {
              address = "127.0.0.1";
              ring = {
                kvstore.store = "inmemory";
                replication_factor = 1;
              };
              final_sleep = "0s";
            };
            chunk_idle_period = "5m";
            chunk_retain_period = "30s";
          };

          schema_config = {
            configs = [
              {
                from = "2018-04-15";
                store = "boltdb";
                object_store = "filesystem";
                schema = "v9";
                index.prefix = "index_";
                index.period = "168h";
              }
            ];
          };

          storage_config = {
            boltdb.directory = "/tmp/loki/index";
            filesystem.directory = "/tmp/loki/chunks";
          };

          limits_config = {
            enforce_metric_name = false;
            reject_old_samples = true;
            reject_old_samples_max_age = "168h";
          };

          chunk_store_config = {
            max_look_back_period = 0;
          };

          table_manager = {
            chunk_tables_provisioning = {
              inactive_read_throughput = 0;
              inactive_write_throughput = 0;
              provisioned_read_throughput = 0;
              provisioned_write_throughput = 0;
            };
            index_tables_provisioning = {
              inactive_read_throughput = 0;
              inactive_write_throughput = 0;
              provisioned_read_throughput = 0;
              provisioned_write_throughput = 0;
            };
            retention_deletes_enabled = false;
            retention_period = 0;
          };
        };
      };

      services.promtail = {
        enable = true;
        configuration = {
          server = {
            http_listen_port = 9080;
            grpc_listen_port = 0;
          };

          positions.filename = "/tmp/positions.yaml";

          client.url = "http://localhost:${toString config.services.loki.configuration.server.http_listen_port}/api/prom/push";

          scrape_configs = [
            {
              job_name = "systemd";
              journal = {
                json = false;
                max_age = "12h";
                path = "/var/log/journal";
                # matches = "_TRANSPORT=kernel";
                labels = {
                  job = "systemd-journal";
                };
              };
              relabel_configs = [
                {
                  source_labels = ["__journal__systemd_unit"];
                  target_label = "unit";
                }
              ];
            }
          ];
        };
      };

      services.prometheus.scrapeConfigs =
        [
          {
            job_name = "node";
            static_configs = [
              {
                targets = ["127.0.0.1:${toString config.services.prometheus.exporters.node.port}"];
              }
            ];
          }
          {
            job_name = "netdata";
            metrics_path = "/api/v1/allmetrics";
            params.format = ["prometheus"];
            honor_labels = true;
            static_configs = [
              {
                targets = ["127.0.0.1:19999"];
              }
            ];
          }
          {
            job_name = "smartctl";
            static_configs = [
              {
                targets = ["127.0.0.1:${toString config.services.prometheus.exporters.smartctl.port}"];
              }
            ];
          }
          {
            job_name = "prometheus_internal";
            static_configs = [
              {
                targets = ["127.0.0.1:${toString config.services.prometheus.port}"];
              }
            ];
          }
        ]
        ++ (lib.lists.optional config.services.nginx.enable {
          job_name = "nginx";
          static_configs = [
            {
              targets = ["127.0.0.1:${toString config.services.prometheus.exporters.nginx.port}"];
            }
          ];
          # }) ++ (lib.optional (builtins.length (lib.attrNames config.services.redis.servers) > 0) {
          #     job_name = "redis";
          #     static_configs = [
          #       {
          #         targets = ["127.0.0.1:${toString config.services.prometheus.exporters.redis.port}"];
          #       }
          #     ];
          # }) ++ (lib.optional (builtins.length (lib.attrNames config.services.openvpn.servers) > 0) {
          #     job_name = "openvpn";
          #     static_configs = [
          #       {
          #         targets = ["127.0.0.1:${toString config.services.prometheus.exporters.openvpn.port}"];
          #       }
          #     ];
        })
        ++ (lib.optional config.services.dnsmasq.enable {
          job_name = "dnsmasq";
          static_configs = [
            {
              targets = ["127.0.0.1:${toString config.services.prometheus.exporters.dnsmasq.port}"];
            }
          ];
        });
      services.prometheus.exporters.nginx = lib.mkIf config.services.nginx.enable {
        enable = true;
        port = 9111;
        listenAddress = "127.0.0.1";
        scrapeUri = "http://localhost:80/nginx_status";
      };
      services.prometheus.exporters.node = {
        enable = true;
        # https://github.com/prometheus/node_exporter#collectors
        enabledCollectors = ["ethtool"];
        port = 9112;
        listenAddress = "127.0.0.1";
      };
      services.prometheus.exporters.smartctl = {
        enable = true;
        port = 9115;
        listenAddress = "127.0.0.1";
      };
      # services.prometheus.exporters.redis = lib.mkIf (builtins.length (lib.attrNames config.services.redis.servers) > 0) {
      #   enable = true;
      #   port = 9119;
      #   listenAddress = "127.0.0.1";
      # };
      # services.prometheus.exporters.openvpn = lib.mkIf (builtins.length (lib.attrNames config.services.openvpn.servers) > 0) {
      #   enable = true;
      #   port = 9121;
      #   listenAddress = "127.0.0.1";
      #   statusPaths = lib.mapAttrsToList (name: _config: "/tmp/openvpn/${name}.status") config.services.openvpn.servers;
      # };
      services.prometheus.exporters.dnsmasq = lib.mkIf config.services.dnsmasq.enable {
        enable = true;
        port = 9211;
        listenAddress = "127.0.0.1";
      };
      services.nginx.statusPage = lib.mkDefault config.services.nginx.enable;
      services.netdata = {
        enable = true;
        config = {
          # web.mode = "none";
          # web."bind to" = "127.0.0.1:19999";
          global = {
            "debug log" = "syslog";
            "access log" = "syslog";
            "error log" = "syslog";
          };
        };
      };
      my.backup_paths = [
        "/var/lib/grafana/data"
      ];
    }
    (mkIf cfg.enable create_database)
  ];
}
