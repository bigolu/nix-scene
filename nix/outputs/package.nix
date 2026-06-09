{
  resholve,
  writeText,
  lib,
  bash,
}:
let
  inherit (lib) getExe fileContents concatMapAttrsStringSep;

  pname = "nix-script";
  interpreter = bash;
  env = { NIX_SCRIPT_MAIN = ../../main.nix; };
in
resholve.mkDerivation {
  inherit pname;
  version = "0.1.0";
  src = writeText pname ''
    #!${getExe interpreter}

    ${concatMapAttrsStringSep "\n" (name: value: "export ${name}=${value}") env}

    ${fileContents ../../nix-script.bash}
  '';
  meta.mainProgram = pname;
  passthru.devshellModule = {
    devshell.packages = [ interpreter ];
  };
  dontUnpack = true;
  installPhase = ''
    install -D $src $out/bin/${pname}
  '';
  solutions.default = {
    scripts = [ "bin/${pname}" ];
    interpreter = "${interpreter}/bin/bash";
    inputs = [ ];
    execer = [ ];
    keep = {
      "$env" = true;
    };
    fake.external = [ "nix" "--" ];
  };
}
