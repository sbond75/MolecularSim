{ lib, stdenv, fetchPypi, buildPythonPackage }:

buildPythonPackage rec {
  pname = "sip";
  version = "4.19.8";

  src = fetchPypi {
    inherit pname version;
    sha256 = "16rb5wk1nr5jja9d4n1ccnfjk5caqzassb8s1sj855171k9pi3am";
  };

}
