{ lib, config, ... }:
{
  sourceDirectory =
    {
      target,
      source,
      outOfStoreSymlinks ? [ ], # these will be symlinked to ~/code/nix-private directly
    }:
    let
      homeDir = config.home.homeDirectory;
      sourceName = builtins.baseNameOf (builtins.toString source);
      absoluteSourcePath = "${homeDir}/code/nix-private/out-of-store-config/${sourceName}";

      allItems = builtins.readDir source;

      inStoreItems = lib.filterAttrs (name: type: !(builtins.elem name outOfStoreSymlinks)) allItems;

      inStoreEntries = lib.mapAttrs' (
        name: type:
        lib.nameValuePair "${target}/${name}" {
          source = source + "/${name}";
        }
      ) inStoreItems;

      outOfStoreEntries = lib.listToAttrs (
        map (
          name:
          lib.nameValuePair "${target}/${name}" {
            source = config.lib.file.mkOutOfStoreSymlink "${absoluteSourcePath}/${name}";
          }
        ) outOfStoreSymlinks
      );
    in
    inStoreEntries // outOfStoreEntries;
}
