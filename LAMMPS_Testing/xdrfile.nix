{ lib, stdenv, fetchFromGitHub, cmake
}:

stdenv.mkDerivation rec {
  name = "xdrfile";
  version = "0d12c950bcc37bda591f7c5ce8256a281b74bd6d";

  buildInputs = [ cmake ];

  src = fetchFromGitHub {
    owner = "chemfiles";
    repo = name;
    rev = "0d12c950bcc37bda591f7c5ce8256a281b74bd6d";
    sha256 = "07paji77azw9lz468cbg5456qnwdg84jb3gyg0jr099xhq0gpp34";
  };
}
