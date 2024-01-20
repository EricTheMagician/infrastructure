{
  stdenv,
  python3,
  python3Packages,
  ...
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "my-nextdns-update";
  version = "1.0.0";
  src = ./.;
  installPhase = ''
    mkdir -p $out
    cp ./update.py $out
  '';
  interpreter = let
    python = python3.withPackages (ps: with ps; [aiohttp]);
  in "${python}/bin/python3";
  passthru = {
    pythonPath = with python3Packages; [nextdns];
    script = "${finalAttrs.finalPackage}/update.py";
  };
})
