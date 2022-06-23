# Based on https://github.com/siraben/siraben-overlay/commit/803248b2aa84767a5427aea5ea1369e15e5dbfbc#diff-075ecd1fe43064efc7ee37f1b861953135864bcb19b25bf797f2fb85e9c01964 and https://ianthehenry.com/posts/how-to-learn-nix/okay-my-actual-first-derivation/

{ lib, stdenv, fetchurl, python27, gcc, blas, lapack,
  enableOpenMP ? true, llvmPackages
}:

let
  my-python-packages = python27.withPackages(ps: with ps; [
    cython
    pyyaml
  ]);
in
stdenv.mkDerivation rec {
  pname = "pDynamo2";
  version = "1.9.0";

  src = fetchurl {
    name = "pDynamo-${version}.tgz";
    url = "https://drive.google.com/uc?id=1aFjQGMMq-0-PxBGm5SyjkALn3ONIE05m&export=download";
    sha256 = "0kjsaqi6ii7i0hg4xcvjpnjl26bhhi4mn0qj6gjyn7xs5n5mki81";

    # https://github.com/NixOS/nixpkgs/issues/31464
    #postFetch = ''your custom unpacker'';
    #postFetch = ''tar xf "$fn"'';
  };

  #unpackPhase = ''tar xf "$fn"'';

  buildInputs = [
    gcc
    blas
    lapack
  ] ++ lib.optional enableOpenMP llvmPackages.openmp
  ;

  propagatedBuildInputs = [
    my-python-packages
  ];

  buildPhase = ''
    #echo $out
    #exit 1
  '';

  installPhase = ''
    cp -a . $out
    cd $out/installation
    python2 Install.py -f ${lib.optional enableOpenMP "--openMP"} --ptAtlas
  '';

  # TODO: fix this shell hook
  # shellHook = ''
  #   PYTHONPATH_backup="$PYTHONPATH"

  #   # This script replaces PYTHONPATH instead of appending to it
  #   source "$out/installation/environment_bash.com"

  #   export PYTHONPATH="$PYTHONPATH_backup$PYTHONPATH"
  # '';
  
  #propagatedBuildInputs = [ ];

  #doCheck = false;
}
