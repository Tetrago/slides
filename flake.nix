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
        inherit (nixpkgs) lib;
        inherit (lib.attrsets) mapAttrs mapAttrsToList;
        inherit (lib.strings) optionalString;

        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          packages = with pkgs; [
            manim-slides
          ];
        };

        packages =
          let
            slides = {
              binary_exploitation = "Binary Exploitation";
            };

            packages = mapAttrs (
              name: value:
              pkgs.callPackage (
                {
                  stdenvNoCC,
                  manim-slides,
                  monaspace,
                  pdf ? false,
                  quality ? "h",
                }:
                stdenvNoCC.mkDerivation {
                  inherit name;
                  src = ./${name};

                  nativeBuildInputs = [
                    manim-slides
                    monaspace
                  ];

                  buildPhase = ''
                    manim-slides render -q ${quality} $src/main.py Main && manim-slides convert --to=html Main ${name}.html ${optionalString pdf "&& manim-slides convert --to=pdf Main ${name}.pdf"}
                  '';

                  installPhase = ''
                    runHook preInstall

                    mkdir -p $out
                    cp -rL ./${name}* $out/

                    runHook postInstall
                  '';

                  postInstall = ''
                    substituteInPlace $out/${name}.html \
                      --replace-fail "Manim Slides" "${value}"
                  '';
                }
              ) { }
            ) slides;
          in
          packages
          // {
            default = pkgs.symlinkJoin {
              name = "slides";
              paths = mapAttrsToList (
                _: v:
                v.override {
                  pdf = true;
                  quality = "k";
                }
              ) packages;
            };
          };
      }
    );
}
