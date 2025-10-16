_:
{
  # Enables Touch ID and Apple Watch authentication for sudo
  security.pam.services.sudo_local.touchIdAuth = true;
  # Enables Touch ID for sudo inside tmux/screen
  security.pam.services.sudo_local.reattach = true;
}
