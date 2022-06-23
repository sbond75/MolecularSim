{ lib, buildPythonPackage, pythonOlder, fetchFromGitHub
, appdirs
, black
, importlib-metadata
, isPy3k
, jedi
, prompt-toolkit
, pygments
, callPackage
, docopt
}:

buildPythonPackage rec {
  pname = "ptpython";
  version = "2.0.5";

  src = fetchFromGitHub {
    owner = "prompt-toolkit";
    repo = "ptpython";
    rev = "6edce3c3d31a5c3f5c071e1a88d62d51a11c42d1";
    sha256 = "0zbvngycqggwzgjyq0nv8x36nvamy63jxrg4cihshl12xc8aqfcp";
  };
  
  propagatedBuildInputs = [
    appdirs
    #black # yes, this is in install_requires
    (callPackage ./jedi.nix {}) #jedi
    (callPackage ./prompt-toolkit.nix {}) #prompt-toolkit
    pygments
    docopt
  ] ++ lib.optionals (pythonOlder "3.8") [ importlib-metadata ];

  # no tests to run
  doCheck = false;

  meta = with lib; {
    description = "An advanced Python REPL";
    license = licenses.bsd3;
    maintainers = with maintainers; [ mlieberman85 ];
    platforms = platforms.all;
  };
}
