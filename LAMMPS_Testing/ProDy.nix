{ lib, stdenv, fetchPypi, buildPythonPackage, callPackage, pythonPackages }:

buildPythonPackage rec {
  pname = "ProDy";
  version = "2.2.0";

  src = fetchPypi {
    inherit pname version;
    sha256 = "16kb5wk1nr5jja9d4n1ccnfjk5caqzassb8s1sj855171k9pi3am";
  };

  propagatedBuildInputs = [
    pythonPackages.numpy (callPackage ./biopython.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;}) pythonPackages.pyparsing
    pythonPackages.scipy.overrideAttrs (oldAttrs: rec {
      installCheck = "";
    });
  ];
}
