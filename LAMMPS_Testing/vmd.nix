{ lib, stdenv, fetchFromGitHub, autoreconfHook, perl, libGL, fltk, tk, tcl, xorg }:

stdenv.mkDerivation rec {
  name = "vmd";
  version = "1.9.3";

  buildInputs = [ autoreconfHook perl libGL fltk tk tcl

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

  src = fetchTarball {
    url = "https://www.ks.uiuc.edu/Research/vmd/vmd-${version}/files/final/vmd-${version}.src.tar.gz";
    sha256 = "081arz6fbf52mng7xhly07mcagw9rjh9wjsarq8xv21v52w9zlvf";
  };

  patchPhase = ''
    substituteInPlace vmd-${version}/configure --replace \
      '# Directory where VMD startup script is installed, should be in users' paths.
$install_bin_dir="/usr/local/bin";

# Directory where VMD files and executables are installed
$install_library_dir="/usr/local/lib/$install_name";' \
      '# Directory where VMD startup script is installed, should be in users' paths.
$install_bin_dir="$out/bin";

# Directory where VMD files and executables are installed
$install_library_dir="$out/lib";'
  '';
}
