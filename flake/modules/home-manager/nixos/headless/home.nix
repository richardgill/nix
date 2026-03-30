{ vars, config, ... }:

{
  imports = [
    ../../shared/headless/home.nix
  ];

  home = {
    homeDirectory = "/home/${vars.userName}";

    sessionPath = [
      "${config.home.homeDirectory}/code/hapi/richard-custom/cli/dist-exe/bun-linux-x64-baseline"
    ];
  };
}
