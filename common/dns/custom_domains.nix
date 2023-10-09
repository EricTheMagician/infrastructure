let
  mini-nix.home = "192.168.88.23";
  mini-nix.ts = "100.64.0.14";

  nixos-workstation.home = "192.168.88.14";

  unraid_apps = import ./unraid_apps.nix;
  unraid.home = "192.168.88.19";
  unraid.ts = "100.64.0.2";

  headscale.ts = "100.64.0.1";

  thepodfather.ts = "100.64.0.18";
  thepodfather.home = "192.168.88.17";

  mini-nix-domains =
    map (domain: {
      inherit domain;
      inherit (mini-nix) home;
      inherit (mini-nix) ts;
    }) [
      "mini-nix"
      "minio-api.eyen.ca"
      "minio-web.eyen.ca"
      "healthchecks.eyen.ca"
      "mini-nix-adguard.eyen.ca"
    ];

  headscale-domains =
    map (domain: {
      inherit domain;
      inherit (headscale) ts;
    })
    [
      "headscale.eyen.ca"
      "headscale"
    ];
  thepodfather-domains =
    map (domain: {
      inherit domain;
      inherit (thepodfather) ts;
      inherit (thepodfather) home;
    }) [
      "cloud.eyen.ca"
      "lldap.eyen.ca"
      "login.eyen.ca"
      "thepodfather"
      "git.eyen.ca"
    ];
in
  [
    {
      domain = "adguard-unraid.eyen.ca";
      inherit (unraid) home;
      inherit (unraid) ts;
    }
    {
      domain = "nixos-workstation";
      inherit (nixos-workstation) home;
    }

    {
      domain = "unraid.eyen.ca";
      home = "192.168.88.19";
      ts = "100.64.0.2";
    }
    {
      domain = "vscode-server-unraid";
      home = "192.168.88.32";
      ts = "100.64.0.11";
    }
    {
      domain = "adguard-unraid.eyen.ca";
      home = "192.168.88.28";
      ts = "100.64.0.9";
    }
  ]
  ++ (map (app: {
      domain = "${app}.eyen.ca";
      inherit (unraid) home;
      inherit (unraid) ts;
    })
    unraid_apps)
  ++ mini-nix-domains
  ++ headscale-domains
  ++ thepodfather-domains
