_:
{
  # Separate from home-manager firefox.nix because /etc requires system-level privileges
  environment.etc."firefox/policies/policies.json".source =
    ../../../home-manager/dot-files/firefox/policies.json;
}
