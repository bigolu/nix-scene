{
  writeTextFile,
  lib,
  bash,
}:
let
  inherit (lib) getExe fileContents toShellVar;
  pname = "nix-script";
in
# PERF: Since we don't cache this build we don't want to have many build
# dependencies. For this reason, we don't use `resholve` since it depends on
# Python.
writeTextFile {
  name = "${pname}";
  executable = true;
  destination = "/bin/${pname}";
  meta.mainProgram = pname;

  text = ''
    #!${getExe bash}

    ${toShellVar "NIX_SCRIPT_ENV" ../../src/env.nix}

    ${fileContents ../../src/nix-script.bash}
  '';

  passthru = {
    devshellModule = {
      devshell.packages = [bash];
    };

    # In the devshell module, we automatically add nix-script to the devshell if
    # there's an attribute in `pkgs` named `nix-script`. To ensure it's our
    # nix-script, we add this attribute.
    isBigoluNixScript = true;
  };
}
