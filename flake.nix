{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-compat.url = "https://git.lix.systems/lix-project/flake-compat/archive/main.tar.gz";
    devshell-modules.url = "github:bigolu/devshell-modules";
  };

  outputs =
    inputs:
    {
      devshellModules.nix-scene = import ./nix/outputs/devshellModules/nix-scene.nix {
        inherit inputs;
      };

      overlays.default = final: _prev: {
        setUpNixScene = final.callPackage ./nix/outputs/legacyPackages/setUpNixScene.nix { };
        nix-scene = final.callPackage ./nix/outputs/package.nix { };
      };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: {
      devShells.dev = inputs.devshell.legacyPackages.${system}.mkShell (
        import ./nix/outputs/devshells/dev.nix { inherit inputs system; }
      );

      legacyPackages.setUpNixScene =
        inputs.nixpkgs.legacyPackages.${system}.callPackage ./nix/outputs/legacyPackages/setUpNixScene.nix
          { };

      packages.default =
        inputs.nixpkgs.legacyPackages.${system}.callPackage ./nix/outputs/package.nix
          { };
    });
}
