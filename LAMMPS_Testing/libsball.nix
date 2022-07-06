{ lib, stdenv, fetchurl, gnumake }:

stdenv.mkDerivation rec {
  name = "libsball";
  version = "1.0";

  buildInputs = [ gnumake ];

  # NOTE: sballfly is within this tar under `libsball/sballfly` which has an OpenGL test program, kind of cool but not sure how to package it and it isn't really needed
  src = fetchurl {
    url = "http://www.photonlimited.com/~johns/code/libsball-${version}.tar.gz";
    sha256 = "15fq6si2zshn3k2v9zb744ha972rzvb2hnql1k4zqyyp90032rxp";
  };
  
  installPhase = ''
    mkdir $out
    install -Dm755 -d testsball $out/bin
    install -Dm755 -d libsball.a $out/lib
    
    mkdir $out/include
    cp *.h $out/include/
  '';
  
  meta = with lib; {
    homepage = "http://www.photonlimited.com/~johns/projects/libsball/";
    description = "LibSBall is a library for communicating with Spaceball 2003, 3000, 3003, or 4000 FLX Six-Degree-Of-Freedom virtual reality controllers made by 3Dconnexion.";
  };
}
