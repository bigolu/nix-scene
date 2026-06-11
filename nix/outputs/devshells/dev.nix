{ inputs, system }:
{ extraModulesPath, ... }:
let
  inherit (builtins) pathExists;
  testConfig = ../../../test-config.nix;
in
{
  imports = [
    "${extraModulesPath}/locale.nix"
    inputs.self.packages.${system}.default.devshellModule
    inputs.self.devshellModules.nix-script
    ./modules/vscode.nix
  ]
  ++ (with inputs.devshell-modules.devshellModules; [
    minimal
    autocomplete
    state
    gcRoot
  ]);

  nix-script = {
    enable = pathExists testConfig;
    config = testConfig;
  };

  gcRoot.roots.flake.inputs = inputs;

  devshell.startup.repl-overlay.text = ''
    export NIX_CONFIG="
      ''${NIX_CONFIG:-}
      extra-repl-overlays = $PRJ_ROOT/nix/repl-overlay.nix
    "
  '';
}
