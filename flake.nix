{
  description = "Flake for development workflows.";

  inputs = {
    rainix.url = "github:rainprotocol/rainix";
    rain.url = "github:rainlanguage/rain.cli";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      flake-utils,
      rainix,
      rain,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = rainix.pkgs.${system};
      in
      rec {
        packages = {
          rain-dia-prelude = rainix.mkTask.${system} {
            name = "rain-dia-prelude";
            body = ''
              set -euxo pipefail
              ./script/build.sh
            '';
          };
        }
        // rainix.packages.${system};

        devShells.default = pkgs.mkShell {
          packages = [
            packages.rain-dia-prelude
            rain.defaultPackage.${system}
          ];

          inherit (rainix.devShells.${system}.default) shellHook buildInputs nativeBuildInputs;

        };
      }
    );

}
