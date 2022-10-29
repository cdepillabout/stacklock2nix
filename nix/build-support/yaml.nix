{ runCommand, remarshal }:

path:

let
  jsonOutputDrv =
    runCommand
      "from-yaml"
      { nativeBuildInputs = [ remarshal ]; }
      "remarshal -if yaml -i \"${path}\" -of json -o \"$out\"";
in
builtins.fromJSON (builtins.readFile jsonOutputDrv);
