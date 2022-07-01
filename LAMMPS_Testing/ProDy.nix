{ lib, stdenv, fetchPypi, buildPythonPackage, callPackage, pythonPackages }:

buildPythonPackage rec {
  pname = "ProDy";
  version = "2.2.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "b4cc7404a203144754164b8b40994e2849fde1cfff06b08492f12fff9d9de7b9";
  };

  propagatedBuildInputs = [
    pythonPackages.numpy (callPackage ./biopython.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;}) pythonPackages.pyparsing pythonPackages.scipy
  ];
}
