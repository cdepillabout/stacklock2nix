
{ runCommand, remarshal }:

# Read a YAML file into a Nix datatype using IFD.
#
# Similar to:
#
# > builtins.fromJSON (builtins.readFile ./somefile)
#
# but takes an input file in YAML instead of JSON.
#
# readYAML :: Path -> a
#
# where `a` is the Nixified version of the input file.
path:

let
  jsonOutputDrv =
    runCommand
      "from-yaml"
      { nativeBuildInputs = [ remarshal ]; }
      "remarshal --stringify -if yaml -i \"${path}\" -of json -o \"$out\"";
in
builtins.fromJSON (builtins.readFile jsonOutputDrv)
