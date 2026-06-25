{ packages, config, system, }:
let
  mergedConfig = (import ./default-config.nix) // (import config);
in
mergedConfig.buildEnv {
  nixpkgs = mergedConfig.nixpkgs { inherit system; };
  inherit packages;
}
