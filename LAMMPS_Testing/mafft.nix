{ stdenv, fetchFromGitHub, gnumake }:

stdenv.mkDerivation rec {
  name = "mafft";
  version = "7.505";

  buildInputs = [ gnumake ];

  # Based on https://mafft.cbrc.jp/alignment/software/source.html
  src = fetchurl {
    url = "https://mafft.cbrc.jp/alignment/software/mafft-${version}-with-extensions-src.tgz";
    sha256 = "07iaji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpp35";
  };
  sourceRoot = "mafft-${version}-with-extensions";

  patchPhase = ''
    substituteInPlace core/Makefile --replace "PREFIX = /usr/local" "PREFIX = $out"
    substituteInPlace extensions/Makefile --replace "PREFIX = /usr/local" "PREFIX = $out"
  '';
  
  preConfigure = ''
    # Build core
    cd core
    make -j $NIX_BUILD_CORES
    make install
    
    # Prepare for extensions build
    cd ../extensions
  '';
}
