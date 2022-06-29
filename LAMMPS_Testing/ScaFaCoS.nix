{ stdenv, fetchFromGitHub, autoreconfHook, mpi, gfortran, gsl, fftw }:

stdenv.mkDerivation rec {
  name = "scafacos";
  version = "1.0.1";

  nativeBuildInputs = [ autoreconfHook ];

  buildInputs = [ mpi gfortran gsl fftw ];
  
  patches = [ ./scafacos-1.0.1-fix.diff # https://download.lammps.org/thirdparty/scafacos-1.0.1-fix.diff
            ];

  configureFlags = [
    "--enable-fcs-solvers=fmm,p2nfft,direct,ewald,p3m"
    "--with-internal-fftw"
    "--with-internal-pfft"
    "--with-internal-pnfft"
    #"--with-pic" # Optional, use if `if(BUILD_SHARED_LIBS)` is true in the CMakeLists.txt in `https://github.com/lammps/lammps/tree/0bc6373386cdaccd7d675d994210b3aa0edfe639/cmake/CMakeLists.txt`
  ];

  # wip trying to fix: {"
  # WARNING: No cycle counter found.  FFTW will use ESTIMATE mode
  #          for all plans.  See the manual for more information.
  # "} when configure phase is running; it seems to want cycle.h on https://github.com/scafacos/scafacos/blob/6fb9549bf6219f890a6b492d4780d1afe0ed2bc1/lib/common/fftw-3.3/configure.ac
  # patchPhase = ''
  #   substituteInPlace lib/common/fftw-3.3/configure.ac --replace \
  #     "CPPFLAGS=\"$CPPFLAGS -I$srcdir/kernel\" \
  #     "CPPFLAGS=\"$CPPFLAGS -I${} -I$srcdir/kernel\""
  # '';

  src = fetchFromGitHub {
    owner = name;
    repo = name;
    rev = "v${version}";
    sha256 = "136k0albxs32ic9y3cl8c6nb0nq7aixayrlwllpbqv0zc0vpwa95";
    fetchSubmodules = true;
  };
}
