{ inputs }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption optionalAttrs;
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (inputs) self;

  # Check `pkgs` before `self` in case the overlay was used
  setUpNixScene = pkgs.setUpNixScene or self.legacyPackages.${system}.setUpNixScene;
  nix-scene = pkgs.nix-scene or self.packages.${system}.default;
in
{
  options.nix-scene = {
    enable = mkOption {
      default = true;
      example = true;
      type = types.bool;
      description = "Whether to enable the setup for `nix-scene`.";
    };

    config = mkOption {
      type = types.oneOf [
        types.str
        types.path
      ];
    };

    preload = mkOption {
      type = types.listOf (
        types.oneOf [
          types.str
          types.path
        ]
      );
      default = [ ];
    };
  };

  config.devshell = optionalAttrs config.nix-scene.enable {
    packages = [ nix-scene ];
    startup = {
      nix-scene.text = setUpNixScene { inherit (config.nix-scene) config preload; };
    };
  };
}
