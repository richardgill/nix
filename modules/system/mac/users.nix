{ vars, lib, config, ... }:
{
  config = {
    users.users.${vars.userName}.home = "/Users/${vars.userName}";

    system.activationScripts.postActivation.text = ''
      echo "Setting up Screenshots folder..."
      SCREENSHOTS_DIR="/Users/${vars.userName}/Screenshots"

      if [ ! -d "$SCREENSHOTS_DIR" ]; then
        mkdir -p "$SCREENSHOTS_DIR"
        chown ${vars.userName}:staff "$SCREENSHOTS_DIR"
      fi

      echo "Setting up Music folder..."
      MUSIC_DIR="${config.customDirs.music}"

      if [ ! -d "$MUSIC_DIR" ]; then
        mkdir -p "$MUSIC_DIR"
        chown ${vars.userName}:staff "$MUSIC_DIR"
      fi
    '';
  };
}
