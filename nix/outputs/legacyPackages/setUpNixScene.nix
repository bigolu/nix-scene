{
  lib,
  writeText,
  stdenv,
}:
{
  config,
  preload ? [ ],
  makeGcRoots,
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
    unique
    ;
  inherit (lib.lists) findFirstIndex;
  inherit (lib.filesystem) listFilesRecursive;

  toEnvVar = name: value: "export ${toShellVar "NIX_SCENE_${name}" value}";

  cacheEnvVar =
    let
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
        pipe script [
          readFile
          (splitString "\n")
          (filter isDirective)
          (map (removePrefix directivePrefix))
          (concatMap (splitString " "))
          # We'll have empty strings if there were consecutive spaces in the string we split.
          (filter (s: s != ""))
          (
            args:
            let
              packagesFlagIndex = findFirstIndex (arg: arg == "--packages" || arg == "-p") null args;
            in
            sublist (packagesFlagIndex + 1) (length args) args
          )
        ];

      buildEnv = packages: import ../../../src/env.nix { inherit packages config; inherit (stdenv.buildPlatform) system; };
    in
    pipe preload [
      (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
      (filter hasDirective)
      (concatMap (
        script:
        let
          packages = parseScript script;
        in
        [
          (join " " packages)
          (buildEnv packages)
        ]
      ))
      unique
      concatLines
      (
        cacheFileContent:
        optionalString (cacheFileContent != "") (
          toEnvVar "CACHE" (writeText "nix-scene-cache" cacheFileContent)
        )
      )
    ];
in
concatLines (
  [ (toEnvVar "CONFIG" config) ]
  ++ optional (cacheEnvVar != "") cacheEnvVar
  ++ optional makeGcRoots (toEnvVar "MAKE_GC_ROOT" "true")
)
