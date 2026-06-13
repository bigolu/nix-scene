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
    sort
    lessThan
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
    optionals
    optionalString
    uniqueStrings
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
          (packages: { inherit packages; })
        ];

      buildEnv = packages: import ../../../src/env.nix { inherit packages config; };
    in
    pipe preload [
      (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
      (filter hasDirective)
      (map (
        script:
        let
          inherit (parseScript script) packages;
        in
        # Normalize the package order so users can get a cache hit regardless of order.
        "${join " " (sort lessThan packages)}\n${buildEnv packages}"
      ))
      uniqueStrings
      concatLines
      (
        cacheLines:
        optionalString (cacheLines != "") (toEnvVar "CACHE" (writeText "nix-scene-cache" cacheLines))
      )
    ];
in
concatLines (
  [
    (toEnvVar "CONFIG" config)
  ]
  ++ optionals (cacheEnvVar != "") [
    cacheEnvVar
  ]
)
