{
  description = "A flake for developing and deploying current project.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        lib = pkgs.lib;

        erlang = pkgs.beam.packages.erlangR25;
        elixir = erlang.elixir_1_14;

        beamPackages = erlang;

        pname = "demo";
        version = "0.1.0";
        src = ./.;

        fetchMixDeps = attrs: beamPackages.fetchMixDeps ({
          inherit elixir;

          pname = "${pname}-mix-deps";
          inherit src version;
        } // attrs);


        mkMixRelease = attrs: beamPackages.mixRelease ({
          inherit elixir;

          inherit pname src version;
        } // attrs);

        shell = with pkgs; mkShell {
          buildInputs = [
            elixir
          ]
          ++ lib.optionals stdenv.isLinux [
            # For ExUnit Notifier on Linux.
            libnotify

            # For file_system on Linux.
            inotify-tools
          ]
          ++ lib.optionals stdenv.isDarwin [
            # For ExUnit Notifier on macOS.
            terminal-notifier

            # For file_system on macOS.
            darwin.apple_sdk.frameworks.CoreFoundation
            darwin.apple_sdk.frameworks.CoreServices
          ];

          shellHook = ''
            # allows mix to work on the local directory
            mkdir -p .nix-mix
            mkdir -p .nix-hex
            export MIX_HOME=$PWD/.nix-mix
            export HEX_HOME=$PWD/.nix-hex
            export ERL_LIBS=$HEX_HOME/lib/erlang/lib

            # concat PATH
            export PATH=$MIX_HOME/bin:$PATH
            export PATH=$MIX_HOME/escripts:$PATH
            export PATH=$HEX_HOME/bin:$PATH

            # enable history for IEx
            export ERL_AFLAGS="-kernel shell_history enabled"
          '';
        };

        release =
          let
            mixFodDeps = fetchMixDeps {
              sha256 = "sha256-DPNbSFGWNWacVQpVgsAI+ZYe08E1cX0X1DUyrpmifwg=";
            };
          in
          mkMixRelease {
            inherit mixFodDeps;
          };
      in
      {
        devShells.default = shell;
        packages.default = release;
      }
    );
}
