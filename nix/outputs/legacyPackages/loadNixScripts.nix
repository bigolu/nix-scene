{
  lib,
  writeText,
}:
{
  config,
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
    toList
    splitString
    hasPrefix
    removePrefix
    sublist
    join
    concatLines
    optionalString
    escapeShellArg
    any
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
      packageString = join " " packages;

      env = import ../../../main.nix {
        inherit packageString;
        configFromNixApi = config;
      };
    in
    { inherit env packageString; };
in
pipe paths [
  (concatMap (path: (if pathIsDirectory path then listFilesRecursive else toList) path))
  (filter hasDirective)
  (concatMap (path: with (loadNixScript path); [ packageString env ]))
  concatLines
  (
    cacheLines:
      (
        optionalString (cacheLines != "") ''
          export NIX_SCRIPT_CACHE=${writeText "nix-script-cache" cacheLines}
        ''
      ) + ''
        export NIX_SCRIPT_CONFIG=${escapeShellArg config}
      ''
  )
]
