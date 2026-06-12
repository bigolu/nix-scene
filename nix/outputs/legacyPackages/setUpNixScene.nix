{
  lib,
  writeText,
}:
{
  config,
  preload ? [ ],
}:
let
  inherit (builtins)
    concatMap
    readFile
    filter
    length
    ;
  inherit (lib)
    pipe
    pathIsDirectory
    toList
    splitString
    hasPrefix
    removePrefix
    sublist
    join
    concatLines
    any
    toShellVar
    optional
    optionalString
    ;
  inherit (lib.lists) findFirstIndex;
  inherit (lib.filesystem) listFilesRecursive;

  directivePrefix = "#nix ";

  isDirective = hasPrefix directivePrefix;

  hasDirective =
    file:
    pipe file [
      readFile
      (splitString "\n")
      (any isDirective)
    ];

  parseScript =
    script:
    let
      args = pipe script [
        readFile
        (splitString "\n")
        (filter isDirective)
        (map (removePrefix directivePrefix))
        (concatMap (splitString " "))
        (filter (s: s != ""))
      ];

      packagesFlagIndex = findFirstIndex (arg: arg == "--packages" || arg == "-p") null args;
      packages = sublist (packagesFlagIndex + 1) (length args) args;
    in
    {
      inherit packages;
    };

  buildEnv = packages: import ../../../src/env.nix { inherit packages config; };

  toEnvVar = name: value: "export ${toShellVar "NIX_SCENE_${name}" value}";

  cacheEnvVar = pipe preload [
    (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
    (filter hasDirective)
    (concatMap (
      script:
      let
        inherit (parseScript script) packages;
      in
      [
        (join " " packages)
        (buildEnv packages)
      ]
    ))
    concatLines
    (
      cacheLines:
      optionalString (cacheLines != "") (toEnvVar "CACHE" (writeText "nix-scene-cache" cacheLines))
    )
  ];

  envVars = [ (toEnvVar "CONFIG" config) ] ++ optional (cacheEnvVar != "") cacheEnvVar;
in
concatLines envVars
