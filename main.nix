{
  packageString,
  nixpkgsFromFlake ? null,
  nixApiConfig ? null,
}:
let
  inherit (builtins) getEnv;
  calledFromNixApi = nixpkgsFromFlake != null;

  defaultConfig =
    (import ./default-config.nix)
      // (if calledFromNixApi then { nixpkgs = nixpkgsFromFlake; } else {});

  userConfig =
    let
      maybe = getEnv "NIX_SCRIPT_CONFIG";
    in
    if calledFromNixApi && nixApiConfig != null then
      import nixApiConfig
    else if maybe != "" then
      import maybe
    else
      {};

  config = defaultConfig // userConfig;

  packages = config.nixpkgs.lib.splitString " " packageString;
in
config.buildEnv {
  inherit (config) nixpkgs;
  inherit packages;
}
