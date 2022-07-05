{ lib, stdenv, fetchFromGitHub, callPackage, cmake, flex, bison, fftw, openbabel2, libsvm, useCUDA ? true, cudatoolkit, tbb, mpi, qt4, eigen, glew, python3, gsl, doxygen, tetex, blas, boost }:

stdenv.mkDerivation rec {
  name = "ball";
  version = "1.4.2";

  # TODO: `FIND_PACKAGE(LPSolve)` fails although it is non-essential
  buildInputs = [ cmake flex bison fftw openbabel2 (callPackage ./lpsolve.nix {}) libsvm ]
                ++ (lib.optional useCUDA cudatoolkit)
                ++ [ tbb mpi
                     #libsForQt5.qt5.qtwebengine libsForQt5.qt5.qtbase libsForQt5.qt5.qtwebsockets libsForQt5.qt5.qt3d libsForQt5.qt5.qtnetworkauth libsForQt5.qt5.qtwebchannel libsForQt5.qt5.wrapQtAppsHook
                     qt4
                     eigen glew python3 gsl doxygen tetex blas boost ];

  patchPhase = ''
    # Remove tabs from CMakeLists.txt since substituteInPlace doesn't appear to be able to handle them:
    expand -i CMakeLists.txt > CMakeLists2.txt
    mv CMakeLists2.txt CMakeLists.txt

    repl1=$(cat <<- "EOF"
  '' +
"# Generate CMake package configuration for BALL build tree
CONFIGURE_FILE(
        \"\${PROJECT_SOURCE_DIR}/cmake/BALLConfig.cmake.in\"
        \"\${PROJECT_BINARY_DIR}/cmake/BALLConfig.cmake\"
        @ONLY
)
EOF
)
" + ''
    

    substituteInPlace CMakeLists.txt --replace "''${Python3_LIBRARIES}" "" \
      --replace "$repl1" ""
  '';

  cmakeFlags = (if useCUDA then [ "-DUSE_CUDA=YES" ] else []) ++ [ "-DBALL_LICENSE=GPL" "-DUSE_MPI=YES" ];
  
  src = fetchFromGitHub {
    owner = "BALL-Project";
    repo = name;
    rev = "V${builtins.replaceStrings ["."] ["_"] version}";
    sha256 = "0s4yhjzp25n7h30n5nfmzmzqz53fpvmcgjfvyhpnjpxzn5fs0zs3";
  };
}
