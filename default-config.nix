{
  nixpkgs =
    let
      inherit (builtins) pathExists getFlake toString;

      nixpkgsFromUserFlake =
        let
          findFlakeDir =
            directory:
            let
              maybe = directory + /flake.nix;
            in
            if pathExists maybe then
              directory
            else if directory == /. then
              null
            else
              findFlakeDir (directory + /..);

          flakeDir = findFlakeDir ./.;
        in
        if flakeDir == null then
          null
        else
          let
            flake = getFlake (toString flakeDir);
          in
          flake.inputs.nixpkgs or null;

      nixpkgs = if nixpkgsFromUserFlake != null then nixpkgsFromUserFlake else <nixpkgs>;
    in
    import nixpkgs {
      config = { };
      overlays = [ ];
    };

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
