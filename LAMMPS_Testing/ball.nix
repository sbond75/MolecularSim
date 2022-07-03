{ lib, stdenv, fetchFromGitHub, callPackage, cmake, flex, bison, fftw, openbabel2, libsvm, useCUDA ? true, cudatoolkit, tbb, mpi, libsForQt5, eigen, glew, python3 }:

stdenv.mkDerivation rec {
  name = "ball";
  version = "1.4.2";

  buildInputs = [ cmake flex bison fftw openbabel2 (callPackage ./lpsolve.nix {}) libsvm ]
                ++ (lib.optional useCUDA cudatoolkit)
                ++ [ tbb mpi libsForQt5.qt5.qtwebengine libsForQt5.qt5.qtbase libsForQt5.qt5.qtwebsockets libsForQt5.qt5.qt3d libsForQt5.qt5.qtnetworkauth libsForQt5.qt5.qtwebchannel eigen glew python3 ];

  cmakeFlags = (if useCUDA then [ "-DUSE_CUDA" ] else []) ++ [ "-DBALL_LICENSE=GPL" "-DUSE_MPI" ];
  
  src = fetchFromGitHub {
    owner = "BALL-Project";
    repo = name;
    rev = "V${builtins.replaceStrings ["."] ["_"] version}";
    sha256 = "ae39f425db8ecaa75d839063fb1fa2f65fbf7d3d395ab26f6a8648f8a2f5d880";
  };
}
