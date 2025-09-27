{ config, lib, pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # mise and build dependencies for compilation
    mise
    gcc
    gnumake
    pkg-config
    zlib
    zlib.dev
    python3  # global python for node build
  ];

  # Enable nix-ld for dynamically linked executables this is needed to install some packages in mise
  programs.nix-ld.enable = true;
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