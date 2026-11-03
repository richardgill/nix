{
  lib,
  vars,
  config,
  ...
}:
{
  imports = [ ../../shared/headless/optional/local-music.nix ];

  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo "Setting up Music folder..."
    MUSIC_DIR="${config.home-manager.users.${vars.userName}.home.homeDirectory}/Music"

    if [ ! -d "$MUSIC_DIR" ]; then
      mkdir -p "$MUSIC_DIR"
      chown ${vars.userName}:staff "$MUSIC_DIR"
    fi
  '';
}
