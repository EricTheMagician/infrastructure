# Custom packages, that can be defined similarly to ones from nixfinal
# You can build them using 'nix build .#example'
final: prev: rec {
  # example = final.callPackage ./example { };
  nginx.mod_geoip2 = final.callPackage ./nginx-mod-geoip2 {};
  nginx-with-mod_geoip2 = prev.nginx.overrideAttrs (oldAttrs: {
    configureFlags = oldAttrs.configureFlags ++ ["--add-module=${nginx.mod_geoip2}"];
    buildInputs = oldAttrs.buildInputs ++ [final.libmaxminddb];
  });
}
