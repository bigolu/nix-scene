{ nixpkgsFromFlake }:
{
  lib,
  writeText,
}:
{
  config ? null,
  paths ? [],
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
    listFilesRecursive
    toList
    splitString
    hasPrefix
    removePrefix
    sublist
    join
    concatLines
    optionalString
    escapeShellArg
    ;
  inherit (lib.lists) findFirstIndex;

  directivePrefix = "#nix ";

  loadNixScript =
    script:
    let
      args = pipe script [
        readFile
        (splitString "\n")
        (filter (hasPrefix directivePrefix))
        (map (removePrefix directivePrefix))
        (concatMap (splitString " "))
        (filter (s: s != ""))
      ];

      packagesFlagIndex = findFirstIndex (arg: arg == "--packages" || arg == "-p") null args;
      packages = sublist (packagesFlagIndex + 1) (length args) args;
      packageString = join " " packages;

      env = import ../../../main.nix {
        inherit packageString;
        inherit nixpkgsFromFlake;
        nixApiConfig = config;
      };
    in
    {
      inherit env packageString;
    };
in
pipe paths [
  (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
  (map loadNixScript)
  (concatMap (path: with (loadNixScript path); [ packageString env ]))
  concatLines
  (
    cacheLines:
      (
        optionalString (paths != []) ''
          export NIX_SCRIPT_CACHE=${writeText "nix-script-cache" cacheLines}
        ''
      ) + (
        optionalString (config != null) ''
          export NIX_SCRIPT_CONFIG=${escapeShellArg config}
        ''
      )
  )
]
