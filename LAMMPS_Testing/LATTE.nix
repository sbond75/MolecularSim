{ stdenv, fetchFromGitHub, cmake, gfortran, blas }:

stdenv.mkDerivation rec {
  name = "latte";
  version = "1.2.2";

  buildInputs = [ cmake gfortran blas ];

  cmakeFlags = ["../cmake"];

  src = fetchFromGitHub {
    owner = "lanl";
    repo = "LATTE";
    rev = "v${version}";
    sha256 = "1n7gd3p7cjawnlv9jzds6nrslbvx3lcmcqqqykmlnlpp79ig081j";
  };
}
