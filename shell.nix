{ pkgs ? import (builtins.fetchTarball { # https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs :
  # Descriptive name to make the store path easier to identify
  name = "nixos-unstable-2022-06-02";
  # Commit hash for nixos-unstable as of the date above
  url = "https://github.com/NixOS/nixpkgs/archive/d2a0531a0d7c434bd8bb790f41625e44d12300a4.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "13nwivn77w705ii86x1s4zpjld6r2l197pw66cr1nhyyhi5x9f7d";
}) { }}:
with pkgs;

let
  pDynamo = (callPackage ./pDynamo2.nix {});
  my-python-packages = python27.withPackages(ps: with ps; [
    pDynamo
    pyyaml
  ]);
in
mkShell {
  buildInputs = [
    my-python-packages
  ];

  # shellHook = (with { out = pDynamo.outPath; };
  #   pDynamo.shellHook);
  
  # shellHook = ''
  #   PYTHONPATH_backup="$PYTHONPATH"

  #   # This script replaces PYTHONPATH instead of appending to it
  #   source "${builtins.foldl' (x: y: x + y + "\n") "" pDynamo.out}/installation/environment_bash.com"

  #   export PYTHONPATH="$PYTHONPATH_backup$PYTHONPATH"
  # '';

  shellHook = ''source /nix/store/x165imivrma61v7y9c9jc7d2c78dfpil-pDynamo2-1.9.0/installation/environment_bash.com'';
}
