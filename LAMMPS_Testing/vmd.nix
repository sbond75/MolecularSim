{ lib, stdenv, fetchFromGitHub, fetchurl, gnumake, callPackage, perl, libGL, fltk, tk-8_5, tcl-8_5, xorg, libpng, libjpeg,
  withCuda ? false # Seems broken due to https://www.ks.uiuc.edu/Research/vmd/mailing_list/vmd-l/31614.html
, cudatoolkit, linuxPackages, tcsh, bison, xterm, imagemagick, binutils, gnuplot, latex2html, last, python, python27, fetchPypi, buildPythonPackage, which, graphviz, darwin, xxd, tachyon, pkg-config, pythonPackages,
  useVRPN ? true, vrpn, # a virtual reality thing? https://github.com/vrpn/vrpn , https://github.com/vrpn/vrpn/blob/master/vrpn_Tracker.h
  useSpacenav ? true, #libspnav, #spacenavd, # http://spacenav.sourceforge.net/
  useMPI ? true, netcdf-mpi, mpich, netcdf,
  
  intelCompilers ? {} # optional, will try gcc if not provided

  # For plugins #
#, hdf5, sqlite # (Under "Libraries required by plugins" on https://www.ks.uiuc.edu/Research/vmd/plugins/doxygen/compiling.html )
  # #
}:

let
  mafft = (callPackage ./mafft.nix {});
  fasta = (callPackage ./fasta.nix {});
  my-python-packages = (python.withPackages(ps: with ps; [
    #numpy
    (callPackage ./ProDy.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;})
  ]));
  doxygen = (callPackage ./doxygen.nix {CoreServices=darwin.apple_sdk.frameworks.CoreServices;});
in
stdenv.mkDerivation rec {
  name = "vmd";
  version = "1.9.3";

  buildInputs = [ gnumake perl libGL fltk tk-8_5 tcl-8_5 my-python-packages which xxd
                  tachyon libpng libjpeg

                ] ++ (lib.optionals useSpacenav [
                  #[oops, not needed:] (callPackage ./ball.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;}) # https://nixos.wiki/wiki/Qt : "Qt applications can't be called with callPackage, since they expect more inputs. Namely qtbase and wrapQtAppsHook. Instead they should be called with libsForQt5.callPackage."
                  # ^this is the actual one needed:
                  (callPackage ./libsball.nix {})
                  #libspnav #spacenavd
                ]) ++ [
                ] ++ (lib.optionals useMPI [
                  netcdf-mpi
                  mpich # (note: mpich is different from mpi -- they are different implementations. See `vmd-${version}/configure` line 980 and the following commented-out lines for an mpi version which may or may not be working if uncommented.)
                ]) ++ (lib.optionals (!useMPI) [
                  netcdf
                ]) ++ [
                  
                  pkg-config # Used within this nix file only
                  pythonPackages.numpy
                ] ++ (lib.optional useVRPN vrpn) ++ [
                ] ++ (lib.optional withCuda cudatoolkit)
  ++ [ tcsh
       # Linux stuff (TODO: macOS support etc.)
       xorg.libXinerama xorg.xinput xorg.libX11 xorg.libXi
       
       # Linux stuff for misc things mostly within the TCL code of vmd:
       bison xterm binutils gnuplot latex2html mafft fasta python27
       last # For `lastal` used in `plugins/mafft.new/mafft-data/core/pairlocalalign.c`
       imagemagick # For `display` command in `vmd-1.9.3/configure` where it says `$def_imageviewer="display %s";`
       
       doxygen graphviz # <-- Not sure if these two are needed

     ] ++ (lib.optional (intelCompilers != {}) intelCompilers)
  ++ [
     ];

  configureFlags = []
    # These match up with `vmd-${version}/Makefile` under linux.amd64.opengl :
                   ++ (lib.splitString " " ("LINUXAMD64 OPENGL OPENGLPBUFFER FLTK TK " +
                                            #+ "ACTC " +       # <-- not supported for now, and the only mention I found of it was: https://www.ks.uiuc.edu/Research/vmd/mailing_list/vmd-l/21321.html
                                            (if withCuda then "CUDA " else "") +
                                            "IMD LIBSBALL XINERAMA XINPUT " +
                                            #+ "LIBOPTIX " +   # <-- not supported for now -- it's NVIDIA Optix and there doesn't appear to be a Nix package for it yet.
                                            #+ "LIBOSPRAY " +  # <-- not supported for now -- https://github.com/ospray/ospray
                                            "LIBTACHYON VRPN NETCDF COLVARS TCL PYTHON PTHREADS NUMPY SILENT ${if (intelCompilers != {}) then "ICC" else "GCC"}${if useMPI then " MPI" else ""}")) ++ [

                                              #"NOSTATICPLUGINS" # Otherwise it tries to #include "libmolfile_plugin.h" which is from plumed.nix but plumed depends on vmd so this causes infinite recursion
                                              "LIBPNG"
                                              "CONTRIB"

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

  CPATH = lib.makeSearchPathOutput "dev" "include" buildInputs; # https://github.com/NixOS/nix/issues/3276
  # https://gist.github.com/CMCDragonkai/8b5cc041cea4a7e45a9cb89f849eaaf8 #
  LIBRARY_PATH = lib.makeLibraryPath buildInputs;
  #LD_LIBRARY_PATH = lib.makeLibraryPath propagatedBuildInputs;
  # #

  patchPhase = ''
    substituteInPlace plugins/Makefile --replace 'csh -f build.csh' 'tcsh -f build.csh'
  
  ${if withCuda then ''
    # Note: The replacement happens but it doesn't fix the issue here:
    #sed -i 's/\$arch_nvccflags *= *"\([^"]*\)"/$arch_nvccflags    = "-D_FORCE_INLINES \1"/g' vmd-${version}/configure # https://www.ks.uiuc.edu/Research/vmd/mailing_list/vmd-l/31614.html , https://github.com/pjreddie/darknet/pull/16
'' else ""}
    #cat vmd-${version}/configure

    substituteInPlace vmd-${version}/configure --replace \
      '# Directory where VMD startup script is installed, should be in users'"'"' paths.
$install_bin_dir="/usr/local/bin";

# Directory where VMD files and executables are installed
$install_library_dir="/usr/local/lib/$install_name";' \
      '# Directory where VMD startup script is installed, should be in users'"'"' paths.
$install_bin_dir="'"$out/bin"'";

# Directory where VMD files and executables are installed
$install_library_dir="'"$out/lib"'";' \
      --replace \
      '"plugins' \
      "\"$out/plugins" \
      --replace '$python_libs        = "-lpython2.5' '$python_libs        = "-lpython2.7' \
      --replace '$system_libs        = "-ll' '$system_libs        = "' \
      --replace 'LOADLIBES   = \$(LIBDIRS) \$(LIBS) $arch_lopts' 'LOADLIBES   = \$(LIBDIRS) \$(LIBS) $arch_lopts -ljpeg'
# -Wl,--copy-dt-needed-entries' # https://stackoverflow.com/questions/19901934/libpthread-so-0-error-adding-symbols-dso-missing-from-command-line

    patchShebangs vmd-${version}/configure

    # The mega patch to fix all the sins
    #find . -type f -exec sed -i 's/\/usr\/local/

    substituteInPlace vmd-${version}/src/vmd.C --replace "/usr/local/lib/vmd" "$out/lib"
    substituteInPlace vmd-${version}/src/config.h --replace "/usr/local/lib/vmd" "$out/lib"
    substituteInPlace vmd-${version}/src/TclTextInterp.C --replace "/usr/local/lib/vmd" "$out/lib"
    substituteInPlace vmd-${version}/src/AtomParser.C --replace "/usr/ccs/bin/yaccpar" `which yacc` # TODO: <-- untested
    patchShebangs vmd-${version}/bin/vmd.csh
    substituteInPlace vmd-${version}/bin/vmd.csh --replace "/usr/local/lib/vmd" "$out/lib" --replace "/usr/bin/X11/xterm" `which xterm`
    patchShebangs vmd-${version}/bin/vmd.sh
    substituteInPlace vmd-${version}/bin/vmd.sh --replace "/usr/local/lib/vmd" "$out/lib" --replace "/usr/bin/X11/xterm" `which xterm`
  ${if withCuda then ''
    substituteInPlace vmd-${version}/configure --replace '$arch_nvcc        = "/usr/local/cuda-8.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$cuda_dir         = "/usr/local/cuda-8.0";' '$cuda_dir         = "${cudatoolkit}";' --replace '$arch_nvcc     = "/usr/local/cuda-4.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$arch_nvcc     = "/usr/local/cuda-5.5/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$arch_nvcc        = "/usr/local/cuda/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" #--replace '$arch_nvcc        = "/usr/local/cuda-8.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '[ ! -x "/bin/csh" ]' 'false'
    substituteInPlace vmd-${version}/configure --replace "/bin/csh" "`which tcsh`" --replace "/bin/sh" "`which sh`"
'' else ""}
    patchShebangs vmd-${version}/lib/use
    substituteInPlace vmd-${version}/lib/scripts/tcl8.5/clock.tcl --replace 'foreach path {' 'foreach path { /etc/zoneinfo' # https://github.com/NixOS/nixpkgs/issues/65415
    substituteInPlace vmd-${version}/lib/scripts/tcl8.5/ldAix --replace '/usr/ccs/bin/nm' "`which nm`"
    #substituteInPlace vmd-${version}/lib/scripts/tk8.5/demos/tcolor --replace 'foreach i {
    #/' "foreach i { ''${xorg.libX11 TODO this doesn't have it in nix repl}/lib/rgb.txt /"
    patchShebangs vmd-${version}/lib/points/vmd_distribute.pl
    patchShebangs vmd-${version}/lib/points/vmd_data.pl
    substituteInPlace vmd-${version}/scripts/vmd/vmdinit.tcl --replace "/usr/local/lib/vmd" "$out/lib" --replace "/usr/tmp" "/tmp"
    patchShebangs vmd-${version}/scripts/vmd/chemical2vmd
    substituteInPlace vmd-${version}/scripts/vmd/chemical2vmd --replace "/usr/tmp" "/tmp"
    substituteInPlace vmd-${version}/scripts/vmd/save_state.tcl --replace "/usr/local/bin/vmd" "$out/bin/vmd"
    patchShebangs plugins/tablelist/scripts/repair.tcl
    patchShebangs plugins/tablelist/demos/miscWidgets_tile.tcl
    patchShebangs plugins/tablelist/demos/styles_tile.tcl
    patchShebangs plugins/tablelist/demos/tileWidgets.tcl
    patchShebangs plugins/tablelist/demos/miscWidgets.tcl
    patchShebangs plugins/tablelist/demos/styles.tcl
    patchShebangs plugins/tablelist/demos/dirViewer.tcl
    patchShebangs plugins/tablelist/demos/iwidgets_tile.tcl
    patchShebangs plugins/tablelist/demos/embeddedWindows_tile.tcl
    patchShebangs plugins/tablelist/demos/bwidget.tcl
    patchShebangs plugins/tablelist/demos/iwidgets.tcl
    patchShebangs plugins/tablelist/demos/bwidget_tile.tcl
    patchShebangs plugins/tablelist/demos/embeddedWindows.tcl
    patchShebangs plugins/tablelist/demos/dirViewer_tile.tcl
    patchShebangs plugins/membrane/doc/combine.tcl # TODO: handles `#!/usr/local/bin/vmd` (since this is self-referential)?
    substituteInPlace plugins/rmsdvt/rmsdvt-gui.tcl --replace 'lappend possible_locations "/usr/tmp"' 'lappend possible_locations "/tmp"'
    patchShebangs plugins/vmddebug/vmddebug.tcl
    patchShebangs plugins/vmddebug/debugatomsel.tcl
    substituteInPlace plugins/namdserver/namdserver.tcl --replace "/usr/local/lib/vmd" "$out/lib"
    patchShebangs plugins/psfgen/python/setup.py
    substituteInPlace plugins/molfile_plugin/src/cpmdlogplugin.c --replace "/usr/local/lib/vmd" "$out/lib"
    substituteInPlace plugins/molfile_plugin/src/gaussianplugin.c --replace "/usr/local/lib/vmd" "$out/lib"
    substituteInPlace plugins/paratool/paratool_refinement.tcl --replace "/usr/local/bin/gnuplot" "`which gnuplot`"
    patchShebangs plugins/autoionize/doc/sod2pot.tcl
    patchShebangs plugins/autoionize/autoionize.tcl
    substituteInPlace plugins/doc/Doxyfile --replace "/usr/bin/perl" "`which perl`"
    substituteInPlace plugins/doc/Doxyfile --replace "BIN_ABSPATH            = /usr/local/bin/" "BIN_ABSPATH            = $(dirname "`which doxysearch.cgi`")"
    patchShebangs plugins/vmdtkcon/tkcon-2.3/docs/perl.txt
    substituteInPlace plugins/autoimd/doc/ug/index.html --replace "/usr/share/latex2html" "${latex2html}"
    substituteInPlace plugins/autoimd/doc/ug/ug.html --replace "/usr/share/latex2html" "${latex2html}"
    patchShebangs plugins/mafft.new/mafft-data/scripts/mafft-homologs.rb
    substituteInPlace plugins/mafft.new/mafft-data/scripts/mafft-homologs.rb --replace 'mafftpath = "/Network/Servers/sol.scs.uiuc.edu/Volumes/HomeRAID/Homes/jlai7/CVS/plugins/mafft/mafft-data/;/bin/mafft"' "mafftpath = \"`which mafft`\""
    substituteInPlace plugins/mafft.new/mafft-data/scripts/mafft --replace 'FASTA_4_MAFFT=`which fasta34`' 'FASTA_4_MAFFT=`which fasta`'
    patchShebangs plugins/mafft.new/mafft-data/core/mafftash_premafft.tmpl
    substituteInPlace plugins/mafft.new/mafft-data/core/mafftash_premafft.tmpl --replace "/usr/bin/md5sum" "`which md5sum`"
    substituteInPlace plugins/mafft.new/mafft-data/core/Falign_localhom.c --replace "/usr/bin/gnuplot" "`which gnuplot`"
    substituteInPlace plugins/mafft.new/mafft-data/core/Falign.c --replace "/usr/bin/gnuplot" "`which gnuplot`"
    patchShebangs plugins/mafft.new/mafft-data/core/newick2mafft.rb
    patchShebangs plugins/mafft.new/mafft-data/core/mingw64mingw32dll
    patchShebangs plugins/mafft.new/mafft-data/core/mafft-homologs.tmpl
    substituteInPlace plugins/mafft.new/mafft-data/core/mafft-homologs.tmpl --replace 'mafftpath = "_BINDIR/mafft"' "mafftpath = \"`which mafft`\""
    patchShebangs plugins/mafft.new/mafft-data/core/regionalrealignment.rb
    substituteInPlace plugins/mafft.new/mafft-data/core/regionalrealignment.rb --replace "\$MAFFTCOMMAND = '\"/usr/local/bin/mafft\"'" "\$MAFFTCOMMAND = '\"$(which mafft)\"'"
    substituteInPlace plugins/mafft.new/mafft-data/core/univscript.tmpl --replace "-mmacosx-version-min=10.5 -isysroot/Developer/SDKs/MacOSX10.5.sdk -DMACOSX_DEPLOYMENT_TARGET=10.5 -static-libgcc" "" --replace 'CC="$HOME/soft/gcc/usr/local/bin/gcc"' "CC=\"`which gcc`\"" --replace 'CC="gcc-4.0"' "CC=\"`which gcc`\"" --replace 'cp $prog ../binaries' "" --replace 'lipo -create $prog.intel64 $prog.intel32 $prog.ppc32 $prog.ppc64 -output $prog' 'cp $prog.intel64 $prog
cp $prog ../binaries' #'cp $prog.intel64 ../binaries/$(basename "$prog")' # TODO: support more architectures than intel64. It attempts to make a macOS "fat" binary with `lipo`, even including the PowerPC architecture.
    substituteInPlace plugins/mafft.new/mafft-data/core/pairlocalalign.c --replace ':/bin:/usr/bin' "" # (Probably optional)
    patchShebangs plugins/mafft.new/mafft-data/core/mingw64mingw32
    patchShebangs plugins/mafft.new/mafft-data/core/seekquencer_premafft.tmpl
    substituteInPlace plugins/mafft.new/mafft-data/core/seekquencer_premafft.tmpl --replace "/usr/bin/md5sum" "`which md5sum`"
    substituteInPlace plugins/mafft.new/mafft-data/core/Makefile.sos --replace "PREFIX = /usr/local" "PREFIX = $out"
    substituteInPlace plugins/mafft.new/mafft-data/core/mafft.tmpl --replace 'FASTA_4_MAFFT=`which fasta34`' 'FASTA_4_MAFFT=`which fasta`'
    substituteInPlace plugins/mafft.new/mafftEXE --replace 'FASTA_4_MAFFT=`which fasta34`' 'FASTA_4_MAFFT=`which fasta`'
    patchShebangs plugins/topotools/topotools.tcl
    patchShebangs plugins/topotools/topogromacs.tcl
    patchShebangs plugins/topotools/topoimpropers.tcl
    patchShebangs plugins/topotools/topoangles.tcl
    patchShebangs plugins/topotools/topoutils.tcl
    patchShebangs plugins/topotools/topocrossterms.tcl
    patchShebangs plugins/topotools/topohelpers.tcl
    patchShebangs plugins/topotools/topobonds.tcl
    patchShebangs plugins/topotools/topolammps.tcl
    patchShebangs plugins/topotools/topoatoms.tcl
    patchShebangs plugins/topotools/topovarxyz.tcl
    patchShebangs plugins/topotools/topodihedrals.tcl
    substituteInPlace plugins/drugui/drugui.tcl --replace "/usr/bin/python" "`which python`"
    substituteInPlace plugins/fmtool/Makefile.specialbuilds --replace "/usr/local/encap/cuda-1.0" "${cudatoolkit}"
    substituteInPlace plugins/molfile_plugin/src/babelplugin.c --replace '/bin/rm' "`which rm`"
    substituteInPlace plugins/mafft.new/mafft-data/core/dndblast.c --replace '/bin/rm' "`which rm`"
    substituteInPlace plugins/mafft.new/mafft-data/core/dndfast4.c --replace '/bin/rm' "`which rm`"
    patchShebangs plugins/pbctools/doc/pbctools.pl
    patchShebangs plugins/mafft.new/mafft-data/scripts/mafft
    patchShebangs plugins/mafft.new/mafft-data/core/mafft.tmpl
    patchShebangs plugins/mafft.new/mafftEXE
    substituteInPlace plugins/aligntool/cealign.tcl --replace '/bin/csh' "`which tcsh`"
    patchShebangs vmd-${version}/lib/scripts/tcl8.5/ldAix
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/tcolor
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/browse
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/rolodex
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/timer
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/square
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/widget
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/rmt
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/hello
    patchShebangs vmd-${version}/lib/scripts/tk8.5/demos/ixset
    patchShebangs plugins/build.android
    patchShebangs plugins/create_static_header.sh
    patchShebangs plugins/bossconvert/src/Example.sh
    patchShebangs plugins/vmdtkcon/tkcon-2.3/tkcon.tcl
    substituteInPlace plugins/autoimd/namdrun.tcl --replace '/bin/sh' "`which sh`"
    patchShebangs plugins/mafft.new/mafft-data/core/makemergetable.rb
    patchShebangs plugins/build.csh

    substituteInPlace plugins/build.csh --replace 'switch ( `hostname` )
 ## Amazon EC2
 case ip-*-*-*-*:
    echo "Using build settings for Amazon EC2"
    setenv TCLINC -I/home/ec2-user/vmd/lib/tcl/include
    setenv TCLLIB -L/home/ec2-user/vmd/lib/tcl
    cd $unixdir; gmake LINUXAMD64 TCLINC=$TCLINC TCLLIB=$TCLLIB/lib_LINUXAMD64 >& log.LINUXAMD64.$DATE < /dev/null &' 'switch ( "nix" )
 case nix:
    setenv TCLINC -I${tcl-8_5.outPath}/include
    setenv TCLLIB -L${tcl-8_5.outPath}/lib
    echo "Using build settings for nix"
    cd $unixdir; make -j $NIX_BUILD_CORES LINUXAMD64 TCLINC=$TCLINC TCLLIB=$TCLLIB/lib_LINUXAMD64'
  '';

  computeCPATH = ''
    export CPATH="$CPATH:$out/plugins/include:$(python -c "import numpy; print(numpy.get_include())"):$out/plugins/include:`pkg-config --cflags-only-I python | sed 's/ *-I *//' | sed -r 's/ +-I */:/g'`" # The first sed removes only up to the first `-I` (for an include passed to the compiler via cflags from pkg-config). The second sed replaces all remaining `-I`'s with colons so that they are separated as the CPATH requires.
    # ^ python command is from https://github.com/FORTH-ModelBasedTracker/PyOpenPose/issues/26
    # ^ `$out/plugins/include` gets us molfile_plugin.h etc. once the `# Build plugins` part of the `preConfigure` phase is done.
  '';
  
  preConfigure = ''
    ${computeCPATH}


  ${if withCuda then ''
    # Based on https://nixos.wiki/wiki/CUDA
    export CUDA_PATH=${cudatoolkit}
    # export LD_LIBRARY_PATH=${linuxPackages.nvidia_x11}/lib
    export EXTRA_LDFLAGS="-L/lib -L${linuxPackages.nvidia_x11}/lib"
    #export EXTRA_CCFLAGS="-I/usr/include" # <-- ?
'' else ""}

    # Build plugins
    cd plugins
    export PLUGINDIR="$out/plugins"
    make -j $NIX_BUILD_CORES world

    # Pesky molfile plugin
    pushd .
    cd molfile_plugin
    make -j $NIX_BUILD_CORES libmolfile_plugin.h libmolfile_plugin.a
    popd

    # Install plugins
    make -j $NIX_BUILD_CORES distrib

    # Prepare for actual build
    cd ../vmd-${version}
  '';

  postConfigure = ''
    # This is here in case the Makefile gets generated by the configure script.
    # (Assumes we're currently in the `vmd-${version}` folder.)
    #echo "out: $out"
    #echo "realpath of Makefile: $(realpath src/Makefile)" # <-- realpath prints `/build/vmd-1.9.3/src/Makefile`
    #echo "Note: It's ok if some of these don't match (since they were replaced in the configure script and that seems to generate the Makefile) :"
    #substituteInPlace src/Makefile --replace "/usr/local/lib/vmd" "$out/lib" --replace '	if [ ! -d "/usr/local/bin" ]; then \
		#$(MAKEDIR) "/usr/local/bin" ; \' "" --replace "/bin/csh" `which tcsh` --replace "/bin/sh" `which sh` --replace "/usr/local/bin" "$out/bin"
    #cat src/Makefile
  '';
  
  #configureScript = ''vmd-${version}/configure'';

  dontAddPrefix = true; # `--prefix` in the configure script isn't supported
  
  #makeFlags = ''-C vmd-${version}'';

  # preBuild = ''
  #   cd 
  # '';

  preInstall = ''
    ${computeCPATH}

    #make -j $NIX_BUILD_CORES linux.amd64.opengl # Optional, it reconfigures for using ICC instead of GCC though and we already have this set up in a `configureFlags` declaration within Nix code above.

    echo "CPATH: $CPATH"
    cd src
    make veryclean
    make -j $NIX_BUILD_CORES
  '';
}
