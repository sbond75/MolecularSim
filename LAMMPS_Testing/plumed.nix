{ lib, stdenv, fetchFromGitHub, gnumake, gnupatch, python, mpich, blas, lapack, callPackage, graphviz, zlib, fetchPypi, buildPythonPackage, darwin, xxd, pkg-config, gfortran, gsl, fftw, python3, bash-completion

  intelCompilers ? {}
}:

# TODO: fix {`
# checking for libmolfile_plugin.h... no
# configure: WARNING: cannot enable __PLUMED_HAS_EXTERNAL_MOLFILE_PLUGINS`
# `}
let
  vmd = (callPackage ./vmd.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage; intelCompilers=intelCompilers;});
in
stdenv.mkDerivation rec {
  name = "plumed2";
  version = "2.7.4";

  buildInputs = [ gnumake python mpich blas lapack vmd (callPackage ./doxygen.nix {CoreServices=darwin.apple_sdk.frameworks.CoreServices;}) graphviz zlib xxd pkg-config gfortran gsl fftw python3 bash-completion (callPackage ./xdrfile.nix {}) ];

  CPATH = (lib.makeSearchPathOutput "dev" "include" buildInputs) + ":${vmd.outPath}/plugins/LINUXAMD64/molfile"; # https://github.com/NixOS/nix/issues/3276
  # https://gist.github.com/CMCDragonkai/8b5cc041cea4a7e45a9cb89f849eaaf8 #
  LIBRARY_PATH = lib.makeLibraryPath buildInputs + ":${vmd.outPath}/plugins/LINUXAMD64/molfile";
  #LD_LIBRARY_PATH = lib.makeLibraryPath propagatedBuildInputs;
  # #
  
  patchPhase = ''
    for i in src/maketools/*; do
      patchShebangs "$i"
    done

    for i in scripts/*.sh; do
      patchShebangs "$i"
    done

    for i in patches/*.sh; do
      patchShebangs "$i"
    done
  '';

  # To prevent {`
  # configure: WARNING: dependencies tracking disabled - always make clean before make
  # configure: Now we will check compulsory headers and libraries`
  # `}
  preBuild = ''make clean'';

  src = fetchFromGitHub {
    owner = "plumed";
    repo = "plumed2";
    rev = "v${version}";
    sha256 = "07iaji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpp34";
  };
}
