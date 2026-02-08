final: prev: {
  mise = prev.mise.overrideAttrs (old: let
    # Pin mise v2026.2.1 (Node 24.12/24.13 GPG fix); remove overlay once nixpkgs-unstable catches up.
    version = "2026.2.1";
    src = prev.fetchFromGitHub {
      owner = "jdx";
      repo = "mise";
      rev = "v${version}";
      hash = "sha256-7TsSK3mk6tSxvWPNYq8Viyc8x4BYmR/QrqRT/sfetz4=";
    };
    cargoHash = "sha256-/gltCohAPGdCpcCvou7HBG0yioiOaGjnIF60FQzkB+s=";
  in {
    inherit version src cargoHash;
    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = cargoHash;
    };
  });
}
