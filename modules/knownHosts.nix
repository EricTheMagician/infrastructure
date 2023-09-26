{
  # add the hetzner storage box as a known host so that we don't have to manually add it all the time.
  services.openssh.knownHosts = {
    adguard-lxc = {
      hostNames = ["100.64.0.9"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPYEz7rugtLO1sLivXg/lBFEprcD6/qJI9cuhwtvscD";
    };

    headscale = {
      extraHostNames = ["100.64.0.1" "headscale.eyen.ca"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBlI3pYLW1+d7ulkVl3HLc0Fd00AFEm2SZjIEhkxcAIO";
    };

    nixos-workstation = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1hcCW0VOR4Ph92EED+JId6vQs5uoyfVDexS/yVK4MF";
    };

    thepodfather = {
      extraHostNames = ["thepodfather.eyen.ca" "100.64.0.18"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC35qotLgb1j50CodY0nE+N8Uqm8a1/Fo8zL9eSRZ+c9";
    };

    hetzner-backup = {
      hostNames = ["[u322294.your-storagebox.de]:23" "u322294.your-storagebox.de"];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
    };
  };
}
