{ stdenv, fetchurl, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  buildInputs = [ autoreconfHook ];

  src = fetchurl {
    url = "mirror://sourceforge/${name}-${version}.tar.gz";
    sha256 = "295f29c32ecf33c4704f48144bdff565acb3a013bc68516a6de3c2b71671bf20";
  };
}
