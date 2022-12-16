{
  lib,
  ...
}: {
  config.builders.stacklock2nix-builder = {
    type = "pure";
    name = "stacklock2nix-builder";
    subsystem = "haskell";

    build = {
      pkgs,
      ### FUNCTIONS
      # AttrSet -> Bool) -> AttrSet -> [x]
      getCyclicDependencies, # name: version: -> [ {name=; version=; } ]
      getDependencies, # name: version: -> [ {name=; version=; } ]
      getSource, # name: version: -> store-path
      # to get information about the original source spec
      getSourceSpec, # name: version: -> {type="git"; url=""; hash="";}
      ### ATTRIBUTES
      # the contentd of the `_subsystem` field of the dream-lock
      subsystemAttrs, # attrset
      defaultPackageName, # string
      defaultPackageVersion, # string
      # all exported (top-level) package names and versions
      # attrset of pname -> version,
      packages,
      # all existing package names and versions
      # attrset of pname -> versions,
      # where versions is a list of version strings
      packageVersions,
      # function which applies overrides to a package
      # It must be applied by the builder to each individual derivation
      # Example:
      #   produceDerivation name (mkDerivation {...})
      produceDerivation,
      ...
    }: let
      l = lib // builtins;

      # TODO: replace with stacklock2nix builder
      makeTopLevelPackage = pname: version: let
        deps = getDependencies pname version;
        depsSources = map ({
          name,
          version,
        }:
          getSource name version)
        deps;
      in
        pkgs.runCommand
        pname
        {}
        # Completely useless build logic for demo purposes
        ''
          mkdir $out
          for dep in ${toString depsSources}; do
            cp -r $dep $out/$(basename $dep)
          done
        '';

      allPackages =
        l.mapAttrs
        (
          name: ver: {
            ${ver} = makeTopLevelPackage name ver;
          }
        )
        packages;
    in {
      packages = allPackages;
    };
  };
}
