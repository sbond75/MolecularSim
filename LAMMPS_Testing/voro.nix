{ lib, stdenv, fetchFromGitHub
, gnumake
}:

stdenv.mkDerivation rec {
  version = "0.4.6";
  pname = "voro";

  src = fetchFromGitHub {
    owner = "chr1shr";
    repo = pname;
    rev = "v${version}";
    sha256 = "0rxyb662w9y3xadyxz2x7gvc7mafbhl13szdc55fsk5sygpdlkv5";
  };

  buildInputs = [ gnumake ];

  patchPhase = ''
    substituteInPlace config.mk --replace \
      "# Installation directory
PREFIX=/usr/local

# Install command
INSTALL=install

# Flags for install command for executable
IFLAGS_EXEC=-m 0755

# Flags for install command for non-executable files
IFLAGS=-m 0644" \
      "# Installation directory
PREFIX=$out

# Install command
INSTALL=install

# Flags for install command for executable
IFLAGS_EXEC=-m 0755

# Flags for install command for non-executable files
IFLAGS=-m 0644"
  '';
  
  #preConfigure = ''ls -la'';
}
