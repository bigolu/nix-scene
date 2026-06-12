{ packages, config, script, }:
let
  mergedConfig = (import ./default-config.nix) // (import config);
in
mergedConfig.buildEnv {
  inherit (mergedConfig) nixpkgs;
  inherit packages script;
}
