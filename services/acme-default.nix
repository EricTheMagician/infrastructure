{
  security.acme.acceptTerms = true;
  security.acme.defaults.reloadServices = ["nginx"];
  security.acme.certs."eyen.ca" = {
    domain = "*.eyen.ca";
  };
}
