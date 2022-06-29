{ stdenv, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "scafacos";
  version = "1.0.1";

  buildInputs = [ autoreconfHook ];

  src = fetchFromGitHub {
    owner = name;
    repo = name;
    rev = "v${version}";
    sha256 = "0fv5vldmwd6qrdv2wkk946dk9rn9nrv3c84ldvvqqn1spxfzgiop";
  };
}
