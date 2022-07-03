{ stdenv, fetchFromGitHub, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  buildInputs = [ autoreconfHook ];

  src = fetchurl {
    url = "mirror://sourceforge/${name}-${version}.tar.gz";
    sha256 = "266oqw7abxzj371xiy0x99dzb4m2s28mjk88i2yfyfnd7vrji9p6";
  };
}
