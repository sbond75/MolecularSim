{ lib
, buildPythonPackage
, fetchPypi
, fetchpatch
, pythonAtLeast
, pythonOlder
, pytestCheckHook
}:

buildPythonPackage rec {
  pname = "parso";
  version = "0.7.1";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1f9fc99mjx0h2ad4mgsid728nnmw58hvnq3411g8ljlr9dr49fna";
  };

  checkInputs = [ pytestCheckHook ];

  disabledTests = lib.optionals (pythonAtLeast "3.10") [
    # python changed exception message format in 3.10, 3.10 not yet supported
    "test_python_exception_matches"
  ];

  meta = with lib; {
    description = "A Python Parser";
    homepage = "https://parso.readthedocs.io/en/latest/";
    changelog = "https://github.com/davidhalter/parso/blob/master/CHANGELOG.rst";
    license = licenses.mit;
  };
}
