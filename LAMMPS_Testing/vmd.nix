{ lib, stdenv, fetchFromGitHub, fetchurl, gnumake, perl, libGL, fltk, tk, tcl, xorg }:

stdenv.mkDerivation rec {
  name = "vmd";
  version = "1.9.3";

  buildInputs = [ gnumake perl libGL fltk tk tcl

                  # Linux stuff (TODO: macOS support etc.)
                  xorg.libXinerama xorg.xinput ];

  configureFlags = []
                   ++ (lib.splitString " " ("LINUXAMD64 OPENGL OPENGLPBUFFER FLTK TK ACTC "
                                        #+ "CUDA "
                                        + "IMD LIBSBALL XINERAMA XINPUT LIBOPTIX LIBOSPRAY LIBTACHYON VRPN NETCDF COLVARS TCL PYTHON PTHREADS NUMPY SILENT ICC")) ++ [

# Misc other options:
# "ACTC"
# "AVX512"
# "CUDA"
# "OPENCL"
# "MPI"
# "IMD"
# "VRPN"
# "LIBSBALL"
# "XINERAMA"
# "XINPUT"
# "TDCONNEXION"
# "LIBGELATO"
# "LIBOPTIX"
# "LIBOSPRAY"
# "LIBTACHYON"
# "LIBPNG"
# "NETCDF"
# "NOSTATICPLUGIN"
# "CONTRIB"
# "TCL"
# "PYTHON"
# "PTHREADS"
# "NUMPY"
  ];

  src = fetchurl {
    url = "https://www.ks.uiuc.edu/Research/vmd/vmd-${version}/files/final/vmd-${version}.src.tar.gz";
    sha256 = "0a7ijps3qmp2qkz0ys31bd96dkz3vg1vdm0fa7z21minr16k3p2v";
  };
  sourceRoot = "."; # To fix "unpacker produced multiple directories" ( https://nix-dev.science.uu.narkive.com/E0kF0Rh2/fetchurl-and-unpacker-produced-multiple-directories )

  patchPhase = ''
    substituteInPlace vmd-${version}/configure --replace \
      '# Directory where VMD startup script is installed, should be in users'"'"' paths.
$install_bin_dir="/usr/local/bin";

# Directory where VMD files and executables are installed
$install_library_dir="/usr/local/lib/$install_name";' \
      '# Directory where VMD startup script is installed, should be in users'"'"' paths.
$install_bin_dir="$out/bin";

# Directory where VMD files and executables are installed
$install_library_dir="$out/lib";'

    patchShebangs vmd-${version}/configure
  '';

  configureScript = ''vmd-${version}/configure'';

  dontAddPrefix = true;
  
  makeFlags = ''-C vmd-${version}'';
}
