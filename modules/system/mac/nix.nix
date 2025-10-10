{ pkgs, ... }:
{
  nix = {
    package = pkgs.nix;
    settings = {
      trusted-users = [
        "root"
        "@admin"
      ];
    };
  };

  # inspo: https://github.com/nix-darwin/nix-darwin/issues/1339
  ids.gids.nixbld = 350;
}
