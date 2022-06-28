{ lib, stdenv, fetchFromGitHub
, cmake
}:

stdenv.mkDerivation rec {
  version = "0.4.6";
  pname = "voro";

  src = fetchFromGitHub {
    owner = "chr1shr";
    repo = pname;
    rev = "v${version}";
    sha256 = "1al1sb9zabb7pdiylky1linm2d61a1pkwmdaylcp9rr08ssgr3bk";
  };

  buildInputs = [ cmake ];
}
