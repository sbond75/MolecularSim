{ lib, stdenv, fetchFromGitHub
, make
}:

stdenv.mkDerivation rec {
  version = "0.4.6";
  pname = "voro";

  src = fetchFromGitHub {
    owner = "chr1shr";
    repo = pname;
    rev = "v${version}";
    sha256 = "0rxyb662w9y3xadyxz2x7gvc7mafbhl13szdc55fsk5sygpdlkv5";
  };

  buildInputs = [ make ];

  #preConfigure = ''ls -la'';
}
