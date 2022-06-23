{ lib
, stdenv
, buildPythonPackage
, pythonOlder
, fetchFromGitHub
, django
, pytestCheckHook
, parso
, callPackage
}:

buildPythonPackage rec {
  pname = "jedi";
  version = "0.17.2";

  src = fetchFromGitHub {
    owner = "davidhalter";
    repo = "jedi";
    rev = "v${version}";
    sha256 = "1ac50v3ajjl1zb1vglmfk6dc5285psmdjrgb3r6awn2w0vgb1y4y";
    fetchSubmodules = true;
  };

  propagatedBuildInputs = [ (callPackage ./parso.nix {}) #parso
                          ];

  checkInputs = [
    #django
    #pytestCheckHook
  ];

  doCheck = false;

  preCheck = ''
    export HOME=$TMPDIR
  '';

  disabledTests = [
    # Assertions mismatches with pytest>=6.0
    "test_completion"

    # sensitive to platform, causes false negatives on darwin
    "test_import"
  ] ++ lib.optionals (stdenv.isAarch64 && pythonOlder "3.9") [
    # AssertionError: assert 'foo' in ['setup']
    "test_init_extension_module"
  ];

  meta = with lib; {
    homepage = "https://github.com/davidhalter/jedi";
    description = "An autocompletion tool for Python that can be used for text editors";
    license = licenses.mit;
    maintainers = with maintainers; [ ];
  };
}
