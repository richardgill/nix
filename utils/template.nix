{ pkgs, ... }:
{
  renderMustache =
    name: template: data:
    pkgs.stdenv.mkDerivation {
      name = "${name}";

      nativeBuildInputs = [ pkgs.mustache-go ];

      passAsFile = [ "jsonData" ];
      jsonData = builtins.toJSON data;

      phases = [
        "buildPhase"
        "installPhase"
      ];

      buildPhase = ''
        ${pkgs.mustache-go}/bin/mustache $jsonDataPath ${template} > rendered_file
      '';

      installPhase = ''
        cp rendered_file $out
      '';
    };
}
