# Shared template builder - creates the builtTemplates derivation
# Import this from other modules that need access to built templates
{
  lib,
  pkgs,
  config,
  osConfig,
  vars,
}:
let
  nixPrivateDir = ../../../../.;

  # Import shared template config
  templateData = import ../../../../utils/template-config.nix {
    inherit lib pkgs;
    config = osConfig;
    userName = vars.userName;
  };

  # Build templates as a Nix derivation (runs at eval time)
  builtTemplates = pkgs.stdenv.mkDerivation {
    name = "dot-files-templates";
    src = nixPrivateDir;

    nativeBuildInputs = [ pkgs.bun ];

    # Write data as JSON file
    passAsFile = [ "dataJson" ];
    dataJson = builtins.toJSON templateData;

    buildPhase = ''
      cd ts-utils
      bun install --frozen-lockfile
      bun run build-templates.ts --data-file $dataJsonPath --outDir $out
    '';

    # buildPhase writes directly to $out, no installPhase needed
    dontInstall = true;
  };

in
{
  inherit builtTemplates templateData;
}
