{
  programs.chromium = {
    enable = true;
    homepageLocation = "https://portal.eyen.ca";
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
    };
    extensions = [
      "cjpalhdlnbpafiamejdnhcphjbkeiagm" # ublock origin
      "nngceckbapebfimnlniiiahkandclblb" # bitwarden
      "iokeahhehimjnekafflcihljlcjccdbe" # alby
      "mnjggcdmjocbbbhaepdhchncahnbgone" # sponson block
      "hnmpcagpplmpfojmgmnngilcnanddlhb" # windscribe
      "cimiefiiaegbelhefglklhhakcgmhkai" # kde/plasma integration
    ];
  };
}
