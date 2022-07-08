{ lib, stdenv, fetchFromGitHub, cmake
}:

stdenv.mkDerivation rec {
  name = "xdrfile";
  version = "0d12c950bcc37bda591f7c5ce8256a281b74bd6d";

  buildInputs = [ cmake ];

  patchPhase = ''
    substituteInPlace CMakeLists.txt --replace 'file(COPY test_data DESTINATION ''${CMAKE_CURRENT_BINARY_DIR})' 'message(STATUS file(COPY ''${CMAKE_CURRENT_SOURCE_DIR}/test_data DESTINATION '"$out))"'
file(COPY ''${CMAKE_CURRENT_SOURCE_DIR}/test_data DESTINATION '"$out)"
  '';

  src = fetchFromGitHub {
    owner = "chemfiles";
    repo = name;
    rev = "0d12c950bcc37bda591f7c5ce8256a281b74bd6d";
    sha256 = "0nyacck6r2li9qi8r7c6wagpd29sbdg21b7bdd84yq6mraja7fs4";
  };
}
