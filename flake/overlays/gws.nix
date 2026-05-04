final: prev: {
  gws = prev.gws.overrideAttrs (old: let
    version = "0.22.5";
    src = prev.fetchFromGitHub {
      owner = "googleworkspace";
      repo = "cli";
      tag = "v${version}";
      hash = "sha256-Bj4gPklufU6p2JpvN6j7QViv7ghSn52jemeXPVXkhlk=";
    };
    cargoHash = "sha256-8vVTACodxxju4x19bNzDKM5xn6btV1UCh+5GUxS70S8=";
  in {
    inherit version src cargoHash;
    cargoDeps = prev.rustPlatform.fetchCargoVendor {
      inherit src;
      hash = cargoHash;
    };
  });
}
