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
  ls -la lp_solve || true
  ls -la lp_solve/bin || true
  ls -la bin || true
    install -Dm755 -d lp_solve/bin/* $out/bin
  '';
  
  src = fetchurl {
    url = "mirror://sourceforge/project/${name}/${name}/${version}/lp_solve_${version}_source.tar.gz"; # https://versaweb.dl.sourceforge.net/project/lpsolve/lpsolve/5.5.2.11/lp_solve_5.5.2.11_source.tar.gz
    sha256 = "0bwh3zl9zl21bmqnk3s33ikhpz7hdli7mhg6x0x97akarksvyjkd";
  };
}
