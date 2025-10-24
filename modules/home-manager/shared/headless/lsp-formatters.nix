{
  pkgs,
  ...
}:
# See also: modules/home-manager/dot-files/mise/config.toml.mustache
{
  home.packages = with pkgs; [
    # LSP servers (not available in mise)
    kotlin-language-server
    nixd
  ];
}
