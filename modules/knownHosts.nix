{
  services.openssh.knownHosts = {
    adguard-lxc = {
      hostNames = ["100.64.0.9"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIPYEz7rugtLO1sLivXg/lBFEprcD6/qJI9cuhwtvscD";
    };

    headscale = {
      extraHostNames = ["100.64.0.1" "headscale.eyen.ca" "headscale"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAION03O8T+c/d40IDwdJDsR4XckbqT6GJoPDLWpyQSp2Q";
    };

    nixos-workstation = {
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1hcCW0VOR4Ph92EED+JId6vQs5uoyfVDexS/yVK4MF";
    };

    thepodfather = {
      extraHostNames = ["thepodfather.eyen.ca" "100.64.0.18" "git.eyen.ca"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIC35qotLgb1j50CodY0nE+N8Uqm8a1/Fo8zL9eSRZ+c9";
    };

    mini-nix = {
      extraHostNames = ["100.64.0.14" "mini-nix.eyen.ca" "mini-nix"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIJql5f5i6dnTFwHwxlGk35PYuYU0pgsh9r4cQqO5+vcc";
    };

    unraid = {
      extraHostNames = ["100.64.0.2" "unraid" "unraid.eyen.ca"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICEjyjaX/it47Hz5JxPmmYRs/uohCkxASG+0X4y5QH2a";
    };

    hetzner-backup = {
      hostNames = ["[u322294.your-storagebox.de]:23" "u322294.your-storagebox.de"];
      publicKey = "ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAQEA5EB5p/5Hp3hGW1oHok+PIOH9Pbn7cnUiGmUEBrCVjnAw+HrKyN8bYVV0dIGllswYXwkG/+bgiBlE6IVIBAq+JwVWu1Sss3KarHY3OvFJUXZoZyRRg/Gc/+LRCE7lyKpwWQ70dbelGRyyJFH36eNv6ySXoUYtGkwlU5IVaHPApOxe4LHPZa/qhSRbPo2hwoh0orCtgejRebNtW5nlx00DNFgsvn8Svz2cIYLxsPVzKgUxs8Zxsxgn+Q/UvR7uq4AbAhyBMLxv7DjJ1pc7PJocuTno2Rw9uMZi1gkjbnmiOh6TTXIEWbnroyIhwc8555uto9melEUmWNQ+C+PwAK+MPw==";
    };
    servarica-backup = {
      hostNames = ["209.209.209.184" "nixos-rica" "100.64.0.10" "borg-backup-server"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINZQok+yyRqdh6YpU3bNzL91WRwRrXQFRYgdXJsUAK4z";
    };
    servarica-luks = {
      hostNames = ["209.209.9.184" "nixos-rica"];
      publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG2u+B53b4AEZop4eWq66JLHXaYZIqbvDN7h77t+oxNV";
    };
  };
}
