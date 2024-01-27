{
  lib,
  config,
  ...
}: {
  options.my.programs.chromium.enable = lib.mkEnableOption "chromium";
  config = let
    dm = config.services.xserver.desktopManager;
    kde5_enabled = dm.plasma5.enable;
    kde6_enabled =
      if (builtins.hasAttr "plasma6" dm)
      then dm.plasma6.enable
      else false;
  in {
    programs.chromium = {
      enable = true;
      homepageLocation = "https://portal.eyen.ca";

      # see https://chromeenterprise.google/policies/ for more info
      extraOpts = {
        "BrowserSignin" = 0;
        "SyncDisabled" = true;
        "PasswordManagerEnabled" = false;
        "SpellcheckEnabled" = true;
        AutofillCreditCardEnabled = false;
        AutofillAddressEnabled = false;
        "SpellcheckLanguage" = [
          "en-CA"
          "fr"
        ];
        NewTabPageLocation = config.programs.chromium.homepageLocation;
      };

      # it's the last bit of the url
      extensions =
        [
          "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
          "nngceckbapebfimnlniiiahkandclblb" # bitwarden
          "iokeahhehimjnekafflcihljlcjccdbe" # alby
          "mnjggcdmjocbbbhaepdhchncahnbgone" # sponson block
          "hnmpcagpplmpfojmgmnngilcnanddlhb" # windscribe
        ]
        ++ lib.optional (kde5_enabled || kde6_enabled) "cimiefiiaegbelhefglklhhakcgmhkai"
        # kde/plasma integration
        ;
    };
  };
}
