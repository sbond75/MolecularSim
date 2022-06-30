{ stdenv, fetchFromGitHub, cmake, gnupatch, python, mpi, blas, lapack, callPackage, zlib }:

stdenv.mkDerivation rec {
  name = "plumed2";
  version = "2.7.4";

  buildInputs = [ cmake python mpi blas lapack (callPackage ./vmd.nix {}) zlib ];

  src = fetchFromGitHub {
    owner = "plumed";
    repo = "plumed2";
    rev = "v${version}";
    sha256 = "c5229146711a71bdb1f62f7c14982cc2f76a1b756d0269c67a9f23b396a1622f";
  };
}
