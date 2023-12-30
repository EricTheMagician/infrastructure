{
  stdenv,
  fetchFromGitHub,
  ...
}:
stdenv.mkDerivation rec {
  name = "ngx_http_geoip2_module-a28ceff";
  version = "3.4";
  src = fetchFromGitHub {
    owner = "leev";
    repo = "ngx_http_geoip2_module";
    rev = "refs/tags/${version}";
    hash = "sha256-CAs1JZsHY7RymSBYbumC2BENsXtZP3p4ljH5QKwz5yg=";
  };
  installPhase = ''
    mkdir $out
    cp *.c config $out/
  '';
  fixupPhase = "";
}
