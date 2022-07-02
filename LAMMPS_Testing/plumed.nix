{ stdenv, fetchFromGitHub, cmake, gnupatch, python, mpi, blas, lapack, callPackage, graphviz, zlib, fetchPypi, buildPythonPackage, darwin,

  intelCompilers # TODO: make this optional
}:

stdenv.mkDerivation rec {
  name = "plumed2";
  version = "2.7.4";

  buildInputs = [ cmake python mpi blas lapack (callPackage ./vmd.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage; intelCompilers=intelCompilers;}) (callPackage ./doxygen.nix {CoreServices=darwin.apple_sdk.frameworks.CoreServices;}) graphviz zlib ];

  src = fetchFromGitHub {
    owner = "plumed";
    repo = "plumed2";
    rev = "v${version}";
    sha256 = "07iaji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpp34";
  };
}
