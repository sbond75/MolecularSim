{ stdenv, fetchFromGitHub, fetchurl, gnumake }:

stdenv.mkDerivation rec {
  name = "fasta";
  version = "36.3.8h";

  buildInputs = [ gnumake ];

  # Based on https://mafft.cbrc.jp/alignment/software/source.html
  src = fetchurl {
    # For fasta 36 only:
    url = "https://fasta.bioch.virginia.edu/wrpearson/fasta/fasta36/fasta-${version}.tar.gz";
    
    sha256 = "04ckih4dwkwxlrz9c3h532wzd2lpic0la4l50fyrd215g4j7m8gm";
  };
  
  preConfigure = ''
    # Prepare for build
    cd src
  '';

  makeFlags = ''-f ../make/Makefile.linux64_sse2''; # TODO: handle other architectures

  installPhase = ''
    install -Dm755 -d ../bin $out
  '';
}
