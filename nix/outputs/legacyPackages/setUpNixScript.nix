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

  loadNixScript =
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

      env = import ../../../src/env.nix { inherit packages config; };
    in
    {
      inherit env packages;
    };

  toEnvVar = name: value: "export ${toShellVar "NIX_SCRIPT_${name}" value}";

  makeCacheEnvVar =
    scripts:
    pipe scripts [
      (concatMap (
        script: with (loadNixScript script); [
          (join " " packages)
          env
        ]
      ))
      concatLines
      (cacheLines: toEnvVar "CACHE" (writeText "nix-script-cache" cacheLines))
    ];
in
pipe preload [
  (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
  (filter hasDirective)
  (scripts: optional (scripts != [ ]) (makeCacheEnvVar scripts))
  (envVars: envVars ++ [ (toEnvVar "CONFIG" config) ])
  concatLines
]
