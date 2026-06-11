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
  setUpNixScript = pkgs.setUpNixScript or self.legacyPackages.${system}.setUpNixScript;
  nix-script =
    if pkgs ? nix-script && pkgs.nix-script ? isBigoluNixScript then
      pkgs.nix-script
    else
      self.packages.${system}.default;
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

  config.devshell = optionalAttrs config.nix-script.enable {
    packages = [ nix-script ];
    startup = {
      nix-script.text = setUpNixScript { inherit (config.nix-script) config preload; };
    };
  };
}
