{ stdenv, fetchFromGitHub, cmake }:

stdenv.mkDerivation rec {
  name = "latte";
  version = "1.2.2";

  buildInputs = [ cmake ];

  src = fetchFromGitHub {
    owner = "lanl";
    repo = "LATTE";
    rev = "v${version}";
    sha256 = "153sxbhri74lc8ix5nndkyxfka9rc60cmsfalx67c2wlj99kvflf";
  };
}
