{ vars, ... }:
{
  programs._1password.enable = true;
  programs._1password-gui = {
    enable = true;
    # Enable this if we use a fingerprint reader for 1Password CLI integration or Linux system authentication in future.
    # polkitPolicyOwners = [ vars.userName ];
  };
}
