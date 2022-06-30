{ stdenv, fetchFromGitHub, cmake }:

# "PACE evaluator library"
stdenv.mkDerivation rec {
  name = "lammps-user-pace";
  version = "2021.10.25.fix2";

  buildInputs = [ cmake ];

  cmakeFlags = [ "../src/CMake" ];

  src = fetchFromGitHub {
    owner = "ICAMS";
    repo = "lammps-user-pace";
    rev = "v.${version}";
    sha256 = "00ldmxakw2pba2d0fw96yf0q5v449d4kv0pbjkyv0975w8664qj6";
  };
}
