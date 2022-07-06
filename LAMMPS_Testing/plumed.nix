{ stdenv, fetchFromGitHub, gnumake, gnupatch, python, mpich, blas, lapack, callPackage, graphviz, zlib, fetchPypi, buildPythonPackage, darwin, xxd, pkg-config, gfortran,

  intelCompilers ? {}
}:

# TODO: fix {`
# checking for libmolfile_plugin.h... no
# configure: WARNING: cannot enable __PLUMED_HAS_EXTERNAL_MOLFILE_PLUGINS`
# `}
stdenv.mkDerivation rec {
  name = "plumed2";
  version = "2.7.4";

  buildInputs = [ gnumake python mpich blas lapack (callPackage ./vmd.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage; intelCompilers=intelCompilers;}) (callPackage ./doxygen.nix {CoreServices=darwin.apple_sdk.frameworks.CoreServices;}) graphviz zlib xxd pkg-config gfortran ];

  patchPhase = ''
    for i in src/maketools/*.sh; do
      patchShebangs "$i"
    done
  '';

  src = fetchFromGitHub {
    owner = "plumed";
    repo = "plumed2";
    rev = "v${version}";
    sha256 = "07iaji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpp34";
  };
}
