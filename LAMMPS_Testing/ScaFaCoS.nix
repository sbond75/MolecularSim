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
  ];

  src = fetchFromGitHub {
    owner = name;
    repo = name;
    rev = "v${version}";
    sha256 = "136k0albxs32ic9y3cl8c6nb0nq7aixayrlwllpbqv0zc0vpwa95";
  };
}
