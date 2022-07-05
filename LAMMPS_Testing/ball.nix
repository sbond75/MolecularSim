{ lib, stdenv, fetchFromGitHub, callPackage, cmake, flex, bison, fftw, openbabel2, libsvm, useCUDA ? true, cudatoolkit, tbb, mpi, qt4, eigen, glew, python, gsl, doxygen, tetex, blas, boost, fetchPypi, buildPythonPackage }:

stdenv.mkDerivation rec {
  name = "ball";
  version = "1.4.2";

  # TODO: `FIND_PACKAGE(LPSolve)` fails although it is non-essential. Probably need to package up lpsolve better and get more of the subprojects in its source folder.. such as bfp/bfp_LUSOL/ccc
  buildInputs = [ cmake flex bison fftw openbabel2 (callPackage ./lpsolve.nix {}) libsvm ]
                ++ (lib.optional useCUDA cudatoolkit)
                ++ [ tbb mpi
                     #libsForQt5.qt5.qtwebengine libsForQt5.qt5.qtbase libsForQt5.qt5.qtwebsockets libsForQt5.qt5.qt3d libsForQt5.qt5.qtnetworkauth libsForQt5.qt5.qtwebchannel libsForQt5.qt5.wrapQtAppsHook
                     qt4
                     eigen glew python gsl doxygen tetex blas boost (callPackage ./sip.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;}) ];

  patchPhase = ''
    repl1=$(cat <<- "EOF"
## Create BALLExport.cmake
STRING(COMPARE LESS ''${CMAKE_MINOR_VERSION} "8" CMAKE_DEPRECATED_VERSION)
IF (''${CMAKE_DEPRECATED_VERSION})
\tMESSAGE(STATUS "Cannot register BALL with CMake! For external code, set the path to BALL during find_package() manually.")
ELSE()
\t## register BALL with CMake so that it can be found easily
\tEXPORT(PACKAGE BALL)
ENDIF()
EOF
)
    repl1="$(echo -e "$repl1")"

    substituteInPlace CMakeLists.txt --replace "$repl1" ""

    substituteInPlace include/BALL/DATATYPE/string.h --replace "char delimiter = '\n');" "char delimiter);"
  '';

  cmakeFlags = (if useCUDA then [ "-DUSE_CUDA=YES" ] else []) ++ [ "-DBALL_LICENSE=GPL" "-DUSE_MPI=YES" "-Wno-dev" ];
  
  src = fetchFromGitHub {
    owner = "BALL-Project";
    repo = name;
    rev = "V${builtins.replaceStrings ["."] ["_"] version}";
    sha256 = "0s4yhjzp25n7h30n5nfmzmzqz53fpvmcgjfvyhpnjpxzn5fs0zs3";
  };
}
