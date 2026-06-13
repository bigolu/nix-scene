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
        PATH=@ENV@/bin"''${PATH:+:$PATH}" exec -- "$@"
      '';
    in
    buildEnv {
      name = "nix-scene-env";
      paths = map (p: getAttrFromPath (splitString "." p) nixpkgs) packages;
      # Users won't be able to resolve a collision by setting priorities.
      ignoreCollisions = true;
      pathsToLink = ["/bin"];
      postBuild = ''
        substitute ${entrypoint} $out/entrypoint --subst-var-by ENV $out
        chmod +x $out/entrypoint
      '';
    };
}
