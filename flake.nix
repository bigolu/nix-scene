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
      devshellModules.nix-script = import ./nix/outputs/devshellModules/nix-script.nix { inherit inputs; };

      overlays.default = final: _prev: {
        loadNixScripts =
          final.callPackage
            (
              import
                ./nix/outputs/legacyPackages/loadNixScripts.nix
                { nixpkgsFromFlake = inputs.nixpkgs.legacyPackages.${final.stdenv.hostPlatform.system}; }
            )
            { };

        nix-script = final.callPackage ./nix/outputs/package.nix { };
      };
    }
    // inputs.flake-utils.lib.eachDefaultSystem (system: {
      devShells.dev = inputs.devshell.legacyPackages.${system}.mkShell (
        import ./nix/outputs/devshells/dev.nix { inherit inputs system; }
      );

      legacyPackages.loadNixScripts =
        let
          nixpkgs = inputs.nixpkgs.legacyPackages.${system};
        in
        nixpkgs.callPackage
          (import ./nix/outputs/legacyPackages/loadNixScripts.nix { nixpkgsFromFlake = nixpkgs; })
          { };

      packages.default =
        inputs.nixpkgs.legacyPackages.${system}.callPackage ./nix/outputs/package.nix
          { };
    });
}
