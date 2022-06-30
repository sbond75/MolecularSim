{ stdenv, fetchFromGitHub, cmake, gnupatch, python, mpi, blas, lapack, callPackage, zlib }:

stdenv.mkDerivation rec {
  name = "plumed2";
  version = "2.7.4";

  buildInputs = [ cmake python mpi blas lapack (callPackage ./vmx.nix {}) zlib ];

  src = fetchFromGitHub {
    owner = "plumed";
    repo = "plumed2";
    rev = "v${version}";
    sha256 = "267rqw7abxzj371xiy0x99dzb4m2s28mjk88i2yfyfnd7vrji9i6";
  };
}
