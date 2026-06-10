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

    ${toShellVar "NIX_SCRIPT_MAIN" ../../main.nix}

    ${fileContents ../../nix-script.bash}
  '';

  passthru.devshellModule = {
    devshell.packages = [bash];
  };
}
