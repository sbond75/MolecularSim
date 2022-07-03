{ stdenv, fetchurl, gnumake, dos2unix, autoreconfHook, automake111x }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  buildInputs = [ gnumake dos2unix autoreconfHook automake111x ];

  patchPhase = ''
    #ls -la
    chmod u+x ./configure

    # Remove carriage returns
    dos2unix ./configure ./configure

    patchShebangs ./configure
  
    echo "---------1"
    aclocal
    echo "---------2"
    libtoolize --force
    echo "---------3"
    #autoheader
    echo "---------4"
  '';

  #autoreconfFlags = ["-fmi"];
  
  src = fetchurl {
    url = "mirror://sourceforge/project/${name}/${name}/${version}/lp_solve_${version}_source.tar.gz"; # https://versaweb.dl.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz
    sha256 = "0bwh3zl9zl21bmqnk3s33ikhpz7hdli7mhg6x0x97akarksvyjkd";
  };
}
