{
  config,
  options,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) mkIf mkMerge mkOption types;
  geoip_database = config.services.geoipupdate.settings.DatabaseDirectory + "/GeoLite2-Country.mmdb";
  nginx_package =
    if !config.my.nginx.ban-ip
    then options.services.nginx.package.default
    else pkgs.nginx-with-mod_geoip2;
in {
  imports = [
    ./acme.nix
  ];
  options.my.nginx = {
    enable = mkOption {
      type = types.bool;
      default = false;
    };
    ban-ip = mkOption {
      type = types.bool;
      default = false;
    };
  };
  config =
    mkMerge [
      (mkIf config.my.nginx.enable {
        services.nginx = {
          enable = true;
          package = nginx_package;
          recommendedBrotliSettings = true;
          recommendedGzipSettings = true;
          recommendedOptimisation = true;
          recommendedProxySettings = true;
          recommendedTlsSettings = true;
          recommendedZstdSettings = true;
          virtualHosts."localhost" = {
            rejectSSL = true;
            default = true;
            locations."/" = {
              return = "444";
            };
          };
        };
        users.users.nginx.extraGroups = [config.security.acme.defaults.group];
        networking.firewall = {
          # ports needed for dns
          allowedTCPPorts = [80 443];
        };
      })
      (
        mkIf config.my.nginx.ban-ip {
          # enable the geoip2-lite country database download
          sops.secrets."geoip/license_key" = {
            sopsFile = ../../secrets/maxmind_geoip.yaml;
          };
          services.geoipupdate = {
            enable = true;
            settings = {
              AccountID = 955233;
              LicenseKey = {_secret = config.sops.secrets."geoip/license_key".path;};
              EditionIDs = ["GeoLite2-Country"];
            };
          };
          # add needed configuration to the nginx config
          services.nginx.appendHttpConfig = ''
            geoip2 ${geoip_database} {
               auto_reload 1d;
               $geoip2_data_country_iso_code country iso_code;
            }

            map $geoip2_data_country_iso_code $allowed_country {
              default yes;
              IN no;
              RU no;
              CN no;
              IR no;
              IQ no;
              KP no;
            }
            # additional settins from the nixos.wiki/wiki/nginx about hardening

            # Add HSTS header with preloading to HTTPS requests.
            # Adding this header to HTTP requests is discouraged
            map $scheme $hsts_header {
                https   "max-age=31536000; includeSubdomains; preload";
            }
            add_header Strict-Transport-Security $hsts_header;

            # Enable CSP for your services.
            #add_header Content-Security-Policy "script-src 'self'; object-src 'none'; base-uri 'none';" always;

            # Minimize information leaked to other domains
            add_header 'Referrer-Policy' 'origin-when-cross-origin';

            # Disable embedding as a frame
            add_header X-Frame-Options DENY;

            # Prevent injection of code in other mime types (XSS Attacks)
            add_header X-Content-Type-Options nosniff;

            # This might create errors
            # I commented it out in case it did create an error
            # proxy_cookie_path / "/; secure; HttpOnly; SameSite=strict";
          '';
        }
      )
    ]
    #  ++ lib.optionals (config.my.nginx.ban-ip) (
    #lib.mapAttrsToList (
    #name: value:
    #mkIf (!(lib.strings.hasInfix "$allowed_country" config.services.nginx.virtualHosts.${name}.extraConfig)) {
    #services.nginx.virtualHosts.${name}.extraConfig = ''
    #if ($allowed_country = no) {
    #return 444;
    #}
    #'';
    #}
    #)
    ##    config.services.nginx.virtualHosts)
    ;
}
