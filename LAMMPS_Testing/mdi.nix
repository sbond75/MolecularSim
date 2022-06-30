{ stdenv, fetchFromGitHub, cmake, python }:

stdenv.mkDerivation rec {
  name = "mdi";
  version = "1.3.2";

  buildInputs = [ cmake python ];

  src = fetchFromGitHub {
    owner = "MolSSI-MDI";
    repo = "MDI_Library";
    rev = "v${version}";
    sha256 = "266rqw7abxzj371xiy0x99dzb4m2s28mjk88i2yfyfnd7vrji9i6";
  };
}
