{ lib, ... }:
{
  options.custom.agentSkills.beeper.enable = lib.mkEnableOption "the Beeper agent skill";
}
