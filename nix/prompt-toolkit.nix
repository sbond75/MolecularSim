{ lib
, buildPythonPackage
, fetchPypi
, pytestCheckHook
, pythonOlder
, six
, wcwidth
}:

buildPythonPackage rec {
  pname = "prompt-toolkit";
  version = "2.0.9";
  format = "setuptools";

  src = fetchPypi {
    pname = "prompt_toolkit";
    inherit version;
    sha256 = "1hg32mayv5v9mwj5gyshfrmd2r03mlvj4dkhwz45zz9qh0fss695";
  };

  propagatedBuildInputs = [
    six
    wcwidth
  ];

  checkInputs = [
    pytestCheckHook
  ];

  disabledTests = [
    "test_pathcompleter_can_expanduser"
  ];

  pythonImportsCheck = [
    "prompt_toolkit"
  ];

  meta = with lib; {
    description = "Python library for building powerful interactive command lines";
    longDescription = ''
      prompt_toolkit could be a replacement for readline, but it can be
      much more than that. It is cross-platform, everything that you build
      with it should run fine on both Unix and Windows systems. Also ships
      with a nice interactive Python shell (called ptpython) built on top.
    '';
    homepage = "https://github.com/jonathanslenders/python-prompt-toolkit";
    license = licenses.bsd3;
    maintainers = with maintainers; [ ];
  };
}
