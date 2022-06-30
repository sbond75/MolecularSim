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
    sha256 = "166rqw7abxzj371xiy0x99dzb4m2s28mjk88i2yfyfnd7vrji9i7";
  };
}
