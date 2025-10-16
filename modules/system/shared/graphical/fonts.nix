{
  pkgs,
  ...
}:
{
  fonts = {
    packages = with pkgs; [
      nerd-fonts.hack
      nerd-fonts.symbols-only
      nerd-fonts.jetbrains-mono
    ];
  };
}
