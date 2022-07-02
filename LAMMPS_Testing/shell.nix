# { pkgs ? import (builtins.fetchTarball { # https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs :
#   # Descriptive name to make the store path easier to identify
#   name = "nixos-unstable-2022-06-02";
#   # Commit hash for nixos-unstable as of the date above
#   url = "https://github.com/NixOS/nixpkgs/archive/d2a0531a0d7c434bd8bb790f41625e44d12300a4.tar.gz";
#   # Hash obtained using `nix-prefetch-url --unpack <url>`
#   sha256 = "13nwivn77w705ii86x1s4zpjld6r2l197pw66cr1nhyyhi5x9f7d";
# }) { }}:
# with pkgs;

{ pkgs ? import (builtins.fetchTarball { # https://nixos.wiki/wiki/FAQ/Pinning_Nixpkgs :
  # Descriptive name to make the store path easier to identify
  name = "nixos-unstable-2020-09-03";
  # Commit hash for nixos-unstable as of the date above
  url = "https://github.com/NixOS/nixpkgs/archive/702d1834218e483ab630a3414a47f3a537f94182.tar.gz";
  # Hash obtained using `nix-prefetch-url --unpack <url>`
  sha256 = "1vs08avqidij5mznb475k5qb74dkjvnsd745aix27qcw55rm0pwb";
}) { }}:
with pkgs;

let
  nur = import (builtins.fetchTarball {
    # Get the revision by choosing a version from https://github.com/nix-community/NUR/commits/master
    url = "https://github.com/nix-community/NUR/archive/9edfb0c8f3fb110ec46216b648be2cbbd3592346.tar.gz";
    # Get the hash by running `nix-prefetch-url --unpack <url>` on the above url
    sha256 = "0mhychkvgkxg1y6p3mvq4699prhr3zw3706xrydjw8bbf6cm5z3p";
  }) {pkgs=pkgs;}; # https://discourse.nixos.org/t/problems-setting-up-nur/10690 , readme on https://github.com/nix-community/NUR
in
mkShell {
  buildInputs = [
    (callPackage ./lammps.nix {withMPI = true; fetchPypi=pythonPackages.fetchPypi; buildPythonPackage=pythonPackages.buildPythonPackage;
                               intelCompilers=nur.repos.dguibert.intelPackages_2020.compilers; # More info: https://github.com/dguibert/nur-packages/blob/master/overlays/intel-compilers-overlay/default.nix
                              }) #lammps
  ];
}
