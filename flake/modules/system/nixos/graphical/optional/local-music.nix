{
  vars,
  ...
}:
{
  imports = [ ../../../shared/headless/optional/local-music.nix ];

  environment.persistence."/persistent".users.${vars.userName}.directories = [
    "Music"
    ".config/cmus"
    ".cache/cmus"
  ];
}
