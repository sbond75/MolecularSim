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
    repl1=$(cat <<- "EOF"
  '' +
"# Generate CMake package configuration for BALL build tree
CONFIGURE_FILE(
\\t\"\${PROJECT_SOURCE_DIR}/cmake/BALLConfig.cmake.in\"
\\t\"\${PROJECT_BINARY_DIR}/cmake/BALLConfig.cmake\"
\\t@ONLY
)

# Generate BALL package config version file
write_basic_package_version_file(
\\t\"\${PROJECT_BINARY_DIR}/cmake/BALLConfigVersion.cmake\"
\\tVERSION \${PROJECT_VERSION}
\\tCOMPATIBILITY AnyNewerVersion
)

# Generate exports
EXPORT(TARGETS BALL
\\tFILE \${PROJECT_BINARY_DIR}/cmake/BALLExport.cmake)

IF(BALL_HAS_VIEW)
\\tEXPORT(TARGETS VIEW
\\t\\tAPPEND
\\t\\tFILE \${PROJECT_BINARY_DIR}/cmake/BALLExport.cmake)
ENDIF()


# Store BALL build directory in the CMake user package registry
EXPORT(PACKAGE BALL)


# Generate CMake package configuration for BALL installation
IF(NOT APPLE)
\\t# Installation path for BALL CMake package configuration files
\\tSET(BALL_CMAKE_EXPORT_PATH \${CMAKE_INSTALL_LIBDIR}/cmake/BALL CACHE PATH \"Path to the cmake package configuration files\")

\\tLIST(REMOVE_ITEM BALL_INCLUDE_DIRS \"\${PROJECT_BINARY_DIR}/include\")
\\tLIST(REMOVE_ITEM BALL_INCLUDE_DIRS \"\${PROJECT_SOURCE_DIR}/include\")
\\tSET(BALL_INCLUDE_DIRS \${BALL_PATH}/include/ \${BALL_INCLUDE_DIRS})

\\tCONFIGURE_FILE(
\\t\\t\"\${PROJECT_SOURCE_DIR}/cmake/BALLConfig.cmake.in\"
\\t\\t\"\${PROJECT_BINARY_DIR}/exports/BALLConfig.cmake\"
\\t\\t@ONLY
\\t)

\\tINSTALL(FILES
\\t\\t\"\${PROJECT_BINARY_DIR}/exports/BALLConfig.cmake\"
\\t\\t\"\${PROJECT_BINARY_DIR}/cmake/BALLConfigVersion.cmake\"
\\t\\tDESTINATION \"\${BALL_CMAKE_EXPORT_PATH}/\"
\\t\\tCOMPONENT   \${COMPONENT_LIBBALL_DEV}
\\t)

\\tINSTALL(EXPORT BALLExportGroup
\\t\\tDESTINATION \${BALL_CMAKE_EXPORT_PATH}
\\t\\tFILE BALLExport.cmake
\\t\\tCOMPONENT \"\${COMPONENT_LIBBALL_DEV}\")
ENDIF()


######################################################
# Generate CTags for BALL project
######################################################
INCLUDE(BALLCTags)
EOF
)
" + ''
    repl1=$"$repl1"
    echo "$repl1"

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
