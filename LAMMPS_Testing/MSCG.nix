{ stdenv, fetchFromGitHub, cmake, lapack, gsl, gromacs }:

stdenv.mkDerivation rec {
  name = "mscg";
  version = "1.7.3.1";

  # Based on https://github.com/uchicago-voth/MSCG-release/blob/master/Install
  buildInputs = [ cmake lapack gsl gromacs ];

  cmakeFlags = [ "../src/CMake" ];

  src = fetchFromGitHub {
    owner = "uchicago-voth";
    repo = "MSCG-release";
    rev = "${version}";
    sha256 = "b659c4206934308fc4b57aa6e668da50444ce664e2e966dc7369349dff118fd5";
  };
}
