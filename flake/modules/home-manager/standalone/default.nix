{
  config,
  lib,
  pkgs,
  ...
}:
let
  loginEnvironment = ''
    if [ -r /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]; then
      . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
    fi
    . "${config.home.profileDirectory}/etc/profile.d/hm-session-vars.sh"
  '';
in
{
  imports = [
    ../linux/headless
    # Credentials are provisioned separately, never copied into the Nix store.
    ../shared/headless/secrets.nix
  ];

  targets.genericLinux = {
    enable = true;
    gpu.enable = false;
  };
  systemd.user.startServices = "sd-switch";

  # Ubuntu lacks xterm-ghostty; ~/.terminfo lets Zsh and tmux recognize Ghostty SSH clients.
  home.file.".terminfo".source = "${pkgs.ghostty.terminfo}/share/terminfo";

  programs.zsh.envExtra = lib.mkBefore ''
    ${loginEnvironment}
    export PATH="$HOME/.local/share/mise/shims:$PATH"
    if [ -r "$HOME/.config/shell/env.sh" ]; then
      . "$HOME/.config/shell/env.sh"
    fi
  '';
  home.file.".bash_profile".source = lib.mkForce (
    pkgs.writeText "bash_profile" (loginEnvironment + builtins.readFile ../dot-files/bash_profile)
  );
}
