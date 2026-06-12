{
  nixpkgs = abort "[nix-scene] Error: You must specify a nixpkgs instance in your configuration file.";

  buildEnv =
    {
      nixpkgs,
      packages,
      script,
    }:
    let
      inherit (nixpkgs) buildEnv writeText bash;
      inherit (nixpkgs.lib) getExe getAttrFromPath splitString;
      inherit (nixpkgs.lib.strings) sanitizeDerivationName;

      entrypoint = writeText "entrypoint" ''
        #!${getExe bash}
        PATH=@NIX_SCENE_ENV@/bin"''${PATH:+:$PATH}" exec -- "$@"
      '';
    in
    buildEnv {
      name = "nix-scene-env-${sanitizeDerivationName (baseNameOf script)}";
      paths = map (p: getAttrFromPath (splitString "." p) nixpkgs) packages;
      # Users won't be able to resolve a collision by setting priorities.
      ignoreCollisions = true;
      pathsToLink = ["/bin"];
      postBuild = ''
        substitute ${entrypoint} $out/entrypoint --subst-var-by NIX_SCENE_ENV $out
        chmod +x $out/entrypoint
      '';
    };
}
