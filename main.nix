{
  packageString,
  configFromNixApi ? null,
}:
let
  inherit (builtins) getEnv;

  defaultConfig = import ./default-config.nix;

  userConfig =
    let
      maybe = getEnv "NIX_SCRIPT_CONFIG";
    in
    if configFromNixApi != null then
      import configFromNixApi
    else if maybe != "" then
      import maybe
    else
      abort "[nix-script] Error: NIX_SCRIPT_CONFIG environment variable is not set";

  config = defaultConfig // userConfig;

  packages = config.nixpkgs.lib.splitString " " packageString;
in
config.buildEnv {
  inherit (config) nixpkgs;
  inherit packages;
}
