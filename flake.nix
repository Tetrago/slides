{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";
    utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { nixpkgs, utils, ... }:
    utils.lib.eachDefaultSystem (
      system:
      let
        inherit (builtins) attrNames readDir;
        inherit (nixpkgs) lib;
        inherit (lib.attrsets) filterAttrs genAttrs mapAttrsToList;
        inherit (lib.strings) optionalString;

        pkgs = nixpkgs.legacyPackages.${system};

        each = fn: genAttrs (attrNames (filterAttrs (_: v: v == "directory") (readDir ./.))) fn;
      in
      {
        packages =
          let
            slides = each (
              name:
              pkgs.callPackage (
                {
                  stdenvNoCC,
                  manim-slides,
                  monaspace,
                  pdf ? false,
                }:
                stdenvNoCC.mkDerivation {
                  inherit name;
                  src = ./${name};

                  nativeBuildInputs = [
                    manim-slides
                    monaspace
                  ];

                  buildPhase = ''
                    manim-slides render $src/main.py Main && manim-slides convert --to=html Main ${name}.html ${optionalString pdf "&& manim-slides convert --to=pdf Main ${name}.pdf"}
                  '';

                  installPhase = ''
                    runHook preInstall

                    mkdir -p $out
                    cp -r ./${name}* $out/

                    runHook postInstall
                  '';
                }
              ) { }
            );
          in
          slides
          // {
            default = pkgs.symlinkJoin {
              name = "slides";
              paths = mapAttrsToList (_: v: v.override { pdf = true; }) slides;
            };
          };
      }
    );
}
