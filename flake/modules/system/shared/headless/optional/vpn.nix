{ pkgs, ... }:
{
  environment.systemPackages = [ pkgs.openvpn ];

  # AirVPN OpenVPN profiles:
  # 1. Go to https://airvpn.org/generator/ and sign in.
  # 2. Choose OpenVPN.
  # 3. Choose Linux or macOS; both work with the openvpn CLI.
  # 4. Start with UDP 443. If that is blocked or unreliable, try TCP 443.
  # 5. Pick a country/server, then generate and download embedded .ovpn profiles.
  # 6. Store profiles outside git:
  #    mkdir -p ~/.config/openvpn/airvpn
  #    chmod 700 ~/.config/openvpn ~/.config/openvpn/airvpn
  #    mv ~/Downloads/AirVPN*.ovpn ~/.config/openvpn/airvpn/
  #    chmod 600 ~/.config/openvpn/airvpn/*.ovpn
  # 7. Connect with the `vpn` script, or directly:
  #    sudo openvpn --config ~/.config/openvpn/airvpn/AirVPN_United-Kingdom_UDP-443-Entry3.ovpn
}
