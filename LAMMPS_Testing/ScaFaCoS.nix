{ stdenv, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "scafacos";
  version = "1.0.1";

  buildInputs = [ autoreconfHook ];

  patches = [ "./scafacos-1.0.1-fix.diff" # https://download.lammps.org/thirdparty/scafacos-1.0.1-fix.diff
            ];

  src = fetchFromGitHub {
    owner = name;
    repo = name;
    rev = "v${version}";
    sha256 = "136k0albxs32ic9y3cl8c6nb0nq7aixayrlwllpbqv0zc0vpwa95";
  };
}
