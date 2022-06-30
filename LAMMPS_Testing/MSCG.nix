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
    sha256 = "166rqw7abxzj371xiy0x99dzb4m2s28mjk88i2yfyfnd7vrji9i6";
  };
}
