{
  writeTextFile,
  lib,
  bash,
  coreutils,
}:
let
  inherit (lib) getExe fileContents toShellVar makeBinPath;
  pname = "nix-scene";
  dependencies = [ coreutils ];
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

    ${toShellVar "NIX_SCENE_ENV" ../../src/env.nix}
    export PATH=${makeBinPath dependencies}"''${PATH:+:$PATH}"

    ${fileContents ../../src/nix-scene.bash}
  '';

  passthru.devshellModule = {
    devshell.packages = [ bash ] ++ dependencies;
  };
}
