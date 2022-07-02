# Based on https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/development/tools/documentation/doxygen/default.nix#L37

{ lib, stdenv, cmake, fetchFromGitHub, python3, flex, bison, qt5, CoreServices, libiconv, buildDoxysearch ? true }:

stdenv.mkDerivation rec {
  pname = "doxygen";
  version = "1.9.4";

  src = fetchFromGitHub {
    owner = "doxygen";
    repo = "doxygen";
    rev = "Release_${lib.replaceStrings [ "." ] [ "_" ] version}";
    sha256 = "18swlw6rsnsv1q82lp441hfl0i505zxlwj7h5wh1jj70x5vzqyhf";
  };

  nativeBuildInputs = [
    cmake
    python3
    flex
    bison
  ];

  buildInputs =
       lib.optionals (qt5 != null) (with qt5; [ qtbase wrapQtAppsHook ])
    ++ lib.optional stdenv.isSunOS libiconv
    ++ lib.optionals stdenv.isDarwin [ CoreServices libiconv ];

  cmakeFlags =
    [ "-DICONV_INCLUDE_DIR=${libiconv}/include" ] ++
    lib.optional (qt5 != null) "-Dbuild_wizard=YES" ++
    lib.optional (buildDoxysearch) "-Dbuild_search=YES";

  NIX_CFLAGS_COMPILE =
    lib.optionalString stdenv.isDarwin "-mmacosx-version-min=10.9";

  meta = {
    license = lib.licenses.gpl2Plus;
    homepage = "https://www.doxygen.nl/";
    changelog = "https://www.doxygen.nl/manual/changelog.html";
    description = "Source code documentation generator tool";

    longDescription = ''
      Doxygen is the de facto standard tool for generating documentation from
      annotated C++ sources, but it also supports other popular programming
      languages such as C, Objective-C, C#, PHP, Java, Python, IDL (Corba,
      Microsoft, and UNO/OpenOffice flavors), Fortran, VHDL and to some extent
      D. It can generate an on-line documentation browser (in HTML) and/or an
      off-line reference manual (in LaTeX) from a set of documented source
      files.
    '';

    platforms = if qt5 != null then lib.platforms.linux else lib.platforms.unix;
  };
}
