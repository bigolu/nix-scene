{ inputs }:
{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption optionalAttrs;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  options.nix-script = {
    config = mkOption {
      type = types.oneOf [ types.str types.path ];
    };

    paths = mkOption {
      type = types.listOf (types.oneOf [ types.str types.path ]);
      default = [];
    };
  };

  config.devshell.startup = optionalAttrs (config.nix-script.paths != []) {
    # Check `pkgs` in case the overlay was used
    nix-script.text = (pkgs.loadNixScripts or inputs.self.legacyPackages.${system}.loadNixScripts) {
      inherit (config.nix-script) config paths;
    };
  };
}