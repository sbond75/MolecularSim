{ stdenv, fetchurl, gnumake, dos2unix, which, autoreconfHook }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  nativeBuildInputs = [ gnumake dos2unix which autoreconfHook ];

  patchPhase = ''
    #ls -la
    chmod u+x ./configure

    # Remove carriage returns
    dos2unix ./configure ./configure

    patchShebangs ./configure

    #export INSTALL=`which install`
    #echo 'install "$@"' > install-sh
    substituteInPlace configure.ac --replace "AC_OUTPUT" $'AC_OUTPUT\nAM_INIT_AUTOMAKE'
    #tail configure.ac
    echo $'all-am:\n\tcd lp_solve && sh ccc' > Makefile.am
    touch NEWS README AUTHORS ChangeLog
    aclocal
    autoconf
    automake --add-missing
    #ls -la
  '';
  
  buildPhase = ''
    cd lp_solve
    sh ccc
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 bin/*/* $out/bin

    #make install
  '';
  
  src = fetchurl {
    url = "mirror://sourceforge/project/${name}/${name}/${version}/lp_solve_${version}_source.tar.gz"; # https://versaweb.dl.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz
    sha256 = "0bwh3zl9zl21bmqnk3s33ikhpz7hdli7mhg6x0x97akarksvyjkd";
  };
}
