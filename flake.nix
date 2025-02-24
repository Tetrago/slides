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
        inherit (nixpkgs.lib.attrsets) filterAttrs genAttrs;

        pkgs = nixpkgs.legacyPackages.${system};

        each = fn: genAttrs (attrNames (filterAttrs (_: v: v == "directory") (readDir ./.))) fn;
      in
      {
        packages = each (
          name:
          pkgs.stdenvNoCC.mkDerivation {
            inherit name;
            src = ./${name};

            nativeBuildInputs = with pkgs; [
              manim-slides
              monaspace
            ];

            buildPhase = ''
              manim-slides render $src/main.py Main && manim-slides convert --to=html Main ${name}.html
            '';

            installPhase = ''
              runHook preInstall

              mkdir -p $out
              cp -r ./${name}* $out/

              runHook postInstall
            '';
          }
        );
      }
    );
}
