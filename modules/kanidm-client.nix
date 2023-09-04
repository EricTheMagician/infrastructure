{
  pkgs,
  config,
  lib,
  ...
}: {
  options = {
    kanidm.pam_allowed_login_groups = lib.mkOption {
      default = ["default_pam_access"];
      type = lib.types.listOf lib.types.str;
      description = "list of kanidm groups to allow pam login access";
    };
  };

  config = {
    services.openssh.authorizedKeysCommand = "${pkgs.kanidm}/bin/kanidm_ssh_authorizedkeys %u";
    services.kanidm = {
      enableClient = true;
      clientSettings = {uri = "https://login.eyen.ca";};
      enablePam = true;
      unixSettings.pam_allowed_login_groups = config.kanidm.pam_allowed_login_groups;
    };
  };
}
