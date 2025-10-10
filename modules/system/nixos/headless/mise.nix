{
  pkgs,
  nixpkgs-unstable,
  ...
}:
# grabbed from lazarus.co.uk website
let
  unstable = import nixpkgs-unstable { inherit (pkgs) system; };
  # Pin specific nixpkgs revision for Node.js 23.11.0
  nodeRevision = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/3e2cf88148e732abc1d259286123e06a9d8c964a.tar.gz";
    sha256 = "sha256:1gvlrbl3fx1fwyb26w5k8rdlxnhzf11si7pzf3khw9n1v4jhqdw0";
  }) { inherit (pkgs) system; };
in
{
  environment.systemPackages = with pkgs; [
    # mise and build dependencies for compilation
    unstable.mise
    gcc
    gnumake
    pkg-config
    zlib
    zlib.dev
    python3 # global python for node build

    # this should be loaded via mise, but currently not possible
    # https://github.com/jbadeau/mise-nix/issues/21
    nodeRevision.nodejs_23
  ];

  # Enable nix-ld for dynamically linked executables this is needed to install some packages in mise
  programs.nix-ld.libraries = with pkgs; [
    stdenv.cc.cc.lib
    openssl
    zlib
    zlib.out
    curl
    python3
    gnumake
    gcc
  ];
}
