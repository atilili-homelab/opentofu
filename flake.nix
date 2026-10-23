{
  description = "***";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

  outputs = {nixpkgs, ...}: let
    systems = ["x86_64-linux" "aarch64-linux"];
    forAllSystems = f:
      nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
        }));

    checkTools = pkgs:
      with pkgs; [
        pre-commit
        gitleaks
        forgejo-runner
      ];
  in {
    devShells = forAllSystems (pkgs: {
      default = pkgs.mkShell {
        packages = checkTools pkgs;
      };
    });
  };
}
