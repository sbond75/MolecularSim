# Based on instructions in https://github.com/openkim/kim-api/blob/master/INSTALL

{ lib, stdenv, fetchFromGitHub
, cmake, pkg-config, doxygen, graphviz, bash-completion
}:

stdenv.mkDerivation rec {
  # LAMMPS has weird versioning converted to ISO 8601 format
  version = "2.3.0";
  pname = "lammps";

  src = fetchFromGitHub {
    owner = "openkim";
    repo = "kim-api";
    rev = "v${version}";
    sha256 = "061mkpj5pp8p1na5qk9x7wcgpx8hjnclflzk1q0a8rvs1kilpkv2";
  };

  buildInputs = [ cmake pkg-config doxygen graphviz bash-completion ];

  # Note: here we let Nix determine the `configurePhase`, `buildPhase`, and `installPhase`, but here are some possible examples (but they are probably not as useful as the prebuilt ones in https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/build-managers/cmake/setup-hook.sh which is called by https://github.com/NixOS/nixpkgs/blob/master/pkgs/development/tools/build-managers/cmake/default.nix ) :
  
  # configurePhase = ''
  #   mkdir build && cd build
  #   cmake .. -DCMAKE_BUILD_TYPE=Release
  # '';

  # buildPhase = ''
  #   make -j$NIX_BUILD_CORES
  # '';
}
