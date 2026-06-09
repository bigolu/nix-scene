{
  nixpkgs = abort "[nix-script] Error: You must provide a nixpkgs instance.";

  buildEnv =
    {
      nixpkgs,
      packages,
    }:
    let
      inherit (nixpkgs) buildEnv writeScript bash;
      inherit (nixpkgs.lib) getExe getAttrFromPath splitString;

      entrypoint = writeScript "entrypoint" ''
        #!${getExe bash}

        set -o errexit
        set -o nounset
        set -o pipefail
        shopt -s nullglob
        shopt -s inherit_errexit

        export PATH=@NIX_SCRIPT_ENV@/bin"''${PATH:+:$PATH}"

        exec -- "$@"
      '';
    in
    buildEnv {
      name = "nix-script-env";
      paths = map (p: getAttrFromPath (splitString "." p) nixpkgs) packages;
      postBuild = ''
        substitute ${entrypoint} $out/entrypoint --subst-var-by NIX_SCRIPT_ENV $out
        chmod +x $out/entrypoint
      '';
    };
}
