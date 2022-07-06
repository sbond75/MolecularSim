{ stdenv, fetchFromGitHub, gnumake }:

stdenv.mkDerivation rec {
  name = "libsball";
  version = "1.0";

  buildInputs = [ gnumake ];

  # NOTE: sballfly is within this tar under `libsball/sballfly` which has an OpenGL test program, kind of cool but not sure how to package it and it isn't really needed
  src = fetchurl {
    url = "http://www.photonlimited.com/~johns/code/libsball-${version}.tar.gz";
    sha256 = "08iaji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpi35";
  };
  
  installPhase = ''
    install -Dm755 libsball.a testsball $out
  '';
  
  meta = with lib; {
    homepage = "http://www.photonlimited.com/~johns/projects/libsball/";
    description = "LibSBall is a library for communicating with Spaceball 2003, 3000, 3003, or 4000 FLX Six-Degree-Of-Freedom virtual reality controllers made by 3Dconnexion.";
  };
}
