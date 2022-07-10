{ lib, stdenv, fetchFromGitHub, cmake
}:

stdenv.mkDerivation rec {
  name = "xdrfile";
  version = "0d12c950bcc37bda591f7c5ce8256a281b74bd6d";

  buildInputs = [ cmake ];

  patchPhase = ''
    substituteInPlace CMakeLists.txt --replace 'if (''${CMAKE_SOURCE_DIR} STREQUAL ''${CMAKE_CURRENT_SOURCE_DIR})
    enable_testing()

    add_executable(xdrfile_test src/xdrfile_c_test.c $<TARGET_OBJECTS:xdrfile>)
    target_include_directories(xdrfile_test PRIVATE include)
    if (UNIX)
        target_link_libraries(xdrfile_test m)
    endif()

    add_test(xdrfile xdrfile_test)
    if(NOT EXISTS "''${CMAKE_CURRENT_BINARY_DIR}/test_data")
        file(COPY test_data DESTINATION ''${CMAKE_CURRENT_BINARY_DIR})
    endif()
endif()' ""
  '';

  src = fetchFromGitHub {
    owner = "chemfiles";
    repo = name;
    rev = version;
    sha256 = "0nyacck6r2li9qi8r7c6wagpd29sbdg21b7bdd84yq6mraja7fs4";
  };
}
