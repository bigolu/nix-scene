{ inputs }:
{ config, lib, pkgs, ... }:
let
  inherit (lib) types mkOption optionalAttrs;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (inputs) self;
in
{
  options.nix-script = {
    enable = mkOption {
      default = true;
      example = true;
      type = types.bool;
      description = "Whether to enable the setup for `nix-script`.";
    };

    config = mkOption {
      type = types.oneOf [ types.str types.path ];
    };

    paths = mkOption {
      type = types.listOf (types.oneOf [ types.str types.path ]);
      default = [];
    };
  };

  # Check `pkgs` before `self` in case the overlay was used
  config.devshell = {
    packages = [ (pkgs.nix-script or self.packages.${system}.nix-script) ];
    startup = optionalAttrs config.nix-script.enable {
      nix-script.text = (pkgs.loadNixScripts or self.legacyPackages.${system}.loadNixScripts) {
        inherit (config.nix-script) config paths;
      };
    };
  };
}
