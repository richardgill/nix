{ vars, ... }:
{
  users.users.${vars.userName}.home = "/Users/${vars.userName}";

  system.activationScripts.postActivation.text = ''
    echo "Setting up Screenshots folder..."
    SCREENSHOTS_DIR="/Users/${vars.userName}/Screenshots"

    if [ ! -d "$SCREENSHOTS_DIR" ]; then
      mkdir -p "$SCREENSHOTS_DIR"
      chown ${vars.userName}:staff "$SCREENSHOTS_DIR"
    fi
  '';
}
