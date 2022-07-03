{ stdenv, fetchurl, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  buildInputs = [ autoreconfHook ];

  src = fetchurl {
    url = "mirror://sourceforge/sourceforge.net/project/${name}/${name}/${version}/lp_solve_${version}_source.tar.gz"; # https://versaweb.dl.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz
    sha256 = "295f29c32ecf33c4704f48144bdff565acb3a013bc68516a6de3c2b71671bf20";
  };
}
