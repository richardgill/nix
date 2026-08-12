{
  vars,
  osConfig,
  ...
}:
{
  home = {
    username = vars.userName;
    stateVersion = "23.11";

    sessionVariables = {
      COLORTERM = "truecolor";
      SSL_CERT_FILE = "/etc/ssl/certs/ca-certificates.crt";
      NTFY_AGENT_TOPIC_FILE = osConfig.sops.secrets."ntfy-agent-topic".path;
      NTFY_GITHUB_TOPIC_FILE = osConfig.sops.secrets."ntfy-github-topic".path;
    };

  };
}
