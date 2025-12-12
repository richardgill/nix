{ vars, ... }:

{
  home = {
    username = vars.userName;
    stateVersion = "23.11";

    sessionVariables = {
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
    };
  };
}
