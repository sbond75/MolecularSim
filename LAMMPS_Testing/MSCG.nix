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
    sha256 = "2n7gd3p7cjawnlv9jzds6nrslbvx3lcmcqqqykmlnlpp79ig081j";
  };
}
