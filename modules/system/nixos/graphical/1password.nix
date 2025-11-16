{ vars, ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Required for CLI integration and system authentication support
    polkitPolicyOwners = [ vars.userName ];
  };
}
