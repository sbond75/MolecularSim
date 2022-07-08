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

  CPATH = lib.makeSearchPathOutput "dev" "include" buildInputs; # https://github.com/NixOS/nix/issues/3276
  # https://gist.github.com/CMCDragonkai/8b5cc041cea4a7e45a9cb89f849eaaf8 #
  LIBRARY_PATH = lib.makeLibraryPath buildInputs;
  #LD_LIBRARY_PATH = lib.makeLibraryPath propagatedBuildInputs;
  # #
  
  patchPhase = ''
    for i in src/maketools/*; do
      patchShebangs "$i"
    done

    for i in scripts/*.sh; do
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
