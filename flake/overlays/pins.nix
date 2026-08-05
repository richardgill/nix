# For each pinned package below, include a comment explaining why it is pinned,
# when it should be removed or revisited, and any relevant upstream/Nixpkgs links.
{ inputs }:
final: prev:
let
  # Example package pin: Firefox is pinned to a nixpkgs revision with Firefox 151.x
  # so the package-pinning pattern stays documented in this repo.
  # usually you leave a link to an issue here: https://link.com/link
  firefox151Pkgs = import inputs.nixpkgs-firefox-151-stable {
    system = prev.stdenv.hostPlatform.system;
    config.allowUnfree = true;
  };

  ghStackVersion = "0.1.0";
  ghStackRelease = {
    aarch64-darwin = {
      asset = "darwin-arm64";
      hash = "sha256-XKmCQaJl1t4BgJXNrl88QNpcp4JFDuwOqRqo4+sYMQM=";
    };
    aarch64-linux = {
      asset = "linux-arm64";
      hash = "sha256-p5ZJ4SGEW3QEEJ3iHWVgHAnIxtAh2Tc4o0KNI5hqiEE=";
    };
    x86_64-linux = {
      asset = "linux-amd64";
      hash = "sha256-NYVS3X3OCkbOFT/hlicM7EgrhPCAlHiQqtQGGo1EvAs=";
    };
  };
  ghStackAsset = ghStackRelease.${prev.stdenv.hostPlatform.system};

  kotlinVersion = "2.2.21";
  kotlinJar =
    artifactId: hash:
    (prev.fetchMavenArtifact {
      groupId = "org.jetbrains.kotlin";
      inherit artifactId hash;
      version = kotlinVersion;
    }).jar;
  kotlinCoroutinesJar =
    (prev.fetchMavenArtifact {
      groupId = "org.jetbrains.kotlinx";
      artifactId = "kotlinx-coroutines-core-jvm";
      version = "1.8.0";
      hash = "sha256-mGCQahk3SQv187BtLw4Q70UeZblbJp8i2vaKPR9QZcU=";
    }).jar;
  kotlinLanguageServerJars = {
    "kotlin-scripting-jvm-host-unshaded-2.1.0.jar" =
      kotlinJar "kotlin-scripting-jvm-host-unshaded" "sha256-KJuD9nKbcunFvVt+85LN2O+KilmvZIH76hPb0tMloKQ=";
    "kotlin-scripting-compiler-2.1.0.jar" =
      kotlinJar "kotlin-scripting-compiler" "sha256-PNJJi5H1MxQ7XsXD/3o3g2h00FnIgmqyFFrPhuw/sK8=";
    "kotlin-compiler-2.1.0.jar" =
      kotlinJar "kotlin-compiler" "sha256-CIXVVG46GNhQmumar3Nd7Me4jgwz/AKHtfdLwIWnz/U=";
    "kotlin-scripting-compiler-impl-2.1.0.jar" =
      kotlinJar "kotlin-scripting-compiler-impl" "sha256-WeAstbEPMiqQZRD0FBDudPvh/KKtgRt5hnA+Bulea1U=";
    "kotlin-reflect-2.1.0.jar" =
      kotlinJar "kotlin-reflect" "sha256-RDgKvzfSRc5cDylPQ1EtHDmllkK/pGOSLHTpaHfPSfg=";
    "kotlin-scripting-jvm-2.1.0.jar" =
      kotlinJar "kotlin-scripting-jvm" "sha256-g4IMX8xdKPBF+RTs1ZALu8+BFbDXAHM03gaf5scGaeY=";
    "kotlin-scripting-common-2.1.0.jar" =
      kotlinJar "kotlin-scripting-common" "sha256-QU7ZHD9eRJKyPLlTeEK0ZRA44l2thBB5OfQ0wiA/KpI=";
    "kotlin-stdlib-jdk8-2.1.0.jar" =
      kotlinJar "kotlin-stdlib-jdk8" "sha256-xiJ1xQ7lkcovgse6QmlreRYAwlhE9H6EvZRgMCoNUjg=";
    "kotlin-stdlib-jdk7-2.1.0.jar" =
      kotlinJar "kotlin-stdlib-jdk7" "sha256-t4WSLxHm2Rpt0ddcsK7xzje4P43g46ITkTnfuCO7iiw=";
    "kotlin-stdlib-2.1.0.jar" =
      kotlinJar "kotlin-stdlib" "sha256-ZVij0jPaVqIJNLMhWfnbX4btWBbvCY94osIj3Gq7ed0=";
    "kotlin-sam-with-receiver-compiler-plugin-2.1.0.jar" =
      kotlinJar "kotlin-sam-with-receiver-compiler-plugin" "sha256-E/JZj3cGNWDkP7yokt8D8pXOUJKhXON7tYyWcbqnims=";
    "kotlin-script-runtime-2.1.0.jar" =
      kotlinJar "kotlin-script-runtime" "sha256-KxUZtCe1FNFTbBtCVnSwP+kUr2N5JAKOmVnGYlRC31E=";
    "kotlinx-coroutines-core-jvm-1.6.4.jar" = kotlinCoroutinesJar;
  };
  replaceKotlinLanguageServerJar = name: jar: "cp ${jar} $out/lib/${name}";
  patchKotlinLanguageServerGradleScript = ''
    gradle_script_dir=$(mktemp -d)
    ${prev.unzip}/bin/unzip -p $out/lib/shared-1.3.13.jar projectClassPathFinder.gradle > $gradle_script_dir/projectClassPathFinder.gradle
    ${prev.python3}/bin/python - $gradle_script_dir/projectClassPathFinder.gradle <<'PY'
    import sys
    from pathlib import Path

    path = Path(sys.argv[1])
    old = """                    variant.getCompileClasspath().each {
                            System.out.println "kotlin-lsp-gradle $it"
                        }
    """
    new = old + """

                        if (variant.hasProperty('unitTestVariant') && variant.unitTestVariant != null) {
                            variant.unitTestVariant.getCompileClasspath().each {
                                System.out.println "kotlin-lsp-gradle $it"
                            }
                        }
    """
    path.write_text(path.read_text().replace(old, new))
    PY
    (cd $gradle_script_dir && ${prev.openjdk}/bin/jar uf $out/lib/shared-1.3.13.jar projectClassPathFinder.gradle)
  '';
in
{
  firefox = firefox151Pkgs.firefox;

  # gh-stack 0.1.0 requires Go 1.26, which is not yet available in this Nixpkgs revision.
  # Remove this release-binary pin when Nixpkgs packages version 0.1.0 or newer.
  # Upstream: https://github.com/github/gh-stack, https://github.com/NixOS/nixpkgs/blob/master/pkgs/by-name/gh/gh-stack/package.nix
  gh-stack = prev.stdenvNoCC.mkDerivation {
    pname = "gh-stack";
    version = ghStackVersion;
    src = prev.fetchurl {
      url = "https://github.com/github/gh-stack/releases/download/v${ghStackVersion}/${ghStackAsset.asset}";
      inherit (ghStackAsset) hash;
    };
    dontUnpack = true;
    installPhase = ''
      install -Dm755 $src $out/bin/gh-stack
    '';
    meta = {
      description = "GitHub CLI extension to use stacked PRs";
      homepage = "https://github.github.com/gh-stack/";
      license = prev.lib.licenses.mit;
      mainProgram = "gh-stack";
    };
  };

  # Neovim is pinned to a 0.13 nightly commit for OS watcher-driven 'autoread'.
  # Remove the pin when Neovim 0.13 is stable and available in Nixpkgs.
  # Upstream: https://github.com/neovim/neovim/pull/37971
  neovim = inputs.neovim-nightly-overlay.packages.${prev.stdenv.hostPlatform.system}.default;

  # kotlin-language-server 1.3.13 bundles Kotlin compiler 2.1.0, which reports false
  # INCOMPATIBLE_CLASS diagnostics for Android projects using Kotlin 2.3 metadata.
  # Revisit when fwcd/kotlin-language-server releases a compiler bump or JetBrains
  # kotlin-lsp has working Android member completions in Neovim.
  # Upstream: https://github.com/fwcd/kotlin-language-server, https://github.com/Kotlin/kotlin-lsp
  kotlin-language-server = prev.kotlin-language-server.overrideAttrs (old: {
    installPhase = old.installPhase + ''
      ${prev.lib.concatStringsSep "\n" (
        prev.lib.mapAttrsToList replaceKotlinLanguageServerJar kotlinLanguageServerJars
      )}
      ${patchKotlinLanguageServerGradleScript}
    '';
  });
}
