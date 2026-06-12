{
  nixpkgs = abort "[nix-scene] Error: You must specify a nixpkgs instance in your configuration file.";

  buildEnv =
    {
      nixpkgs,
      packages,
    }:
    let
      inherit (nixpkgs) buildEnv writeText bash;
      inherit (nixpkgs.lib) getExe getAttrFromPath splitString;

      entrypoint = writeText "entrypoint" ''
        #!${getExe bash}
        PATH=@NIX_SCENE_ENV@/bin"''${PATH:+:$PATH}" exec -- "$@"
      '';
    in
    buildEnv {
      name = "nix-scene-env";
      paths = map (p: getAttrFromPath (splitString "." p) nixpkgs) packages;
      postBuild = ''
        substitute ${entrypoint} $out/entrypoint --subst-var-by NIX_SCENE_ENV $out
        chmod +x $out/entrypoint
      '';
    };
}
