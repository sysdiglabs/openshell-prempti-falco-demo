{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    # openshell 0.0.116 -> 0.1.2, not merged yet: https://github.com/NixOS/nixpkgs/pull/569334
    nixpkgs-openshell.url = "github:NixOS/nixpkgs?ref=pull/569334/head";
  };
  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
      nixpkgs-openshell,
    }:
    let
      overlays.default = final: prev: {
        # Drop once the PR is merged into nixpkgs-unstable.
        openshell = prev.callPackage "${nixpkgs-openshell}/pkgs/by-name/op/openshell/package.nix" { };
        # The nixpkgs package only builds the CLI. The gateway comes from the upstream release (same version).
        openshell-gateway =
          let
            version = "0.1.2";
            assets = {
              aarch64-darwin = "aarch64-apple-darwin";
              aarch64-linux = "aarch64-unknown-linux-gnu";
              x86_64-linux = "x86_64-unknown-linux-gnu";
            };
            hashes = {
              aarch64-darwin = "640068efa16e446d5f4f9ffaec0af769dbab04d686473d2a7bd6bafeb4ef7f45";
              aarch64-linux = "8ec1b6ca5b71ef5085fa51f3244d719a541e8f0d58cc569c7a0d6705b6204397";
              x86_64-linux = "218d887845b3a020ab7535c9985eb9c666d6938f144044957f8b82b42892aadb";
            };
            system = final.stdenv.hostPlatform.system;
          in
          final.stdenv.mkDerivation {
            pname = "openshell-gateway";
            inherit version;
            src = final.fetchurl {
              url = "https://github.com/NVIDIA/OpenShell/releases/download/v${version}/openshell-gateway-${assets.${system}}.tar.gz";
              sha256 = hashes.${system};
            };
            sourceRoot = ".";
            # Linux binaries are dynamically linked (glibc); only the darwin one is tested.
            nativeBuildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.autoPatchelfHook ];
            buildInputs = final.lib.optionals final.stdenv.hostPlatform.isLinux [ final.stdenv.cc.cc.lib ];
            installPhase = "install -Dm755 openshell-gateway $out/bin/openshell-gateway";
            meta.mainProgram = "openshell-gateway";
          };
      };
      flake = flake-utils.lib.eachDefaultSystem (
        system:
        let
          pkgs = import nixpkgs {
            inherit system;
            config.allowUnfree = true;
            overlays = [ self.overlays.default ];
          };
        in
        {
          packages = {
            inherit (pkgs) openshell openshell-gateway;
            default = pkgs.openshell;
          };
          devShells.default =
            with pkgs;
            mkShell {
              packages = [
                just # task runner (justfile)
                openshell # CLI
                openshell-gateway # gateway (upstream release binary)
              ];
              # Docker (colima on macOS) comes from the host.
            };

          formatter = pkgs.nixfmt-tree;
        }
      );
    in
    flake // { inherit overlays; };
}
