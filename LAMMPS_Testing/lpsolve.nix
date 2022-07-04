{ stdenv, fetchurl, gnumake }:

stdenv.mkDerivation rec {
  name = "lpsolve";
  version = "5.5.2.11";

  buildInputs = [ gnumake ];

  buildPhase = ''
    cd lp_solve
    sh ccc
  '';

  installPhase = ''
    mkdir -p $out/bin
    install -Dm755 bin/*/* $out/bin
  '';
  
  src = fetchurl {
    url = "mirror://sourceforge/project/${name}/${name}/${version}/lp_solve_${version}_source.tar.gz"; # https://versaweb.dl.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz
    sha256 = "0bwh3zl9zl21bmqnk3s33ikhpz7hdli7mhg6x0x97akarksvyjkd";
  };
}
