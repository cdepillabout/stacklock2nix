{
  inputs = {
    dream2nix.url = "github:nix-community/dream2nix";
    stacklock2nix.url = "github:cdepillabout/stacklock2nix";

    # some example project containing a stack.yaml.lock
    src.url = "github:NorfairKing/cabal2json";
    src.flake = false;
  };

  outputs = {
    self,
    dream2nix,
    stacklock2nix,
    src,
  } @ inp:
    (dream2nix.lib.makeFlakeOutputs {
      systems = ["x86_64-linux"];
      config.projectRoot = ./.;
      config.modules = [
        stacklock2nix.modules.dream2nix.stacklock2nix-translator
        stacklock2nix.modules.dream2nix.stacklock2nix-builder
      ];
      source = src;
      projects = {
        cabal2json = {
          name = "cabal2json";
          subsystem = "haskell";
          translator = "stacklock2nix-translator";
          builder = "stacklock2nix-builder";
        };
      };
    })
    // {
      # checks.x86_64-linux.linemd = self.packages.x86_64-linux.linemd;
    };
}
