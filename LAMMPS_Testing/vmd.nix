{ lib, stdenv, fetchFromGitHub, fetchurl, gnumake, callPackage, perl, libGL, fltk, tk-8_5, tcl-8_5, xorg, withCuda ? true, cudatoolkit, linuxPackages, tcsh, bison, xterm, imagemagick, binutils, gnuplot, latex2html, last, python, python27, fetchPypi, buildPythonPackage, which, graphviz, darwin, xxd,
  
  intelCompilers ? {} # optional, will try gcc if not provided
}:

let
  mafft = (callPackage ./mafft.nix {});
  fasta = (callPackage ./fasta.nix {});
  my-python-packages = (python.withPackages(ps: with ps; [
    numpy
    (callPackage ./ProDy.nix {fetchPypi=fetchPypi; buildPythonPackage=buildPythonPackage;})
  ]));
  doxygen = (callPackage ./doxygen.nix {CoreServices=darwin.apple_sdk.frameworks.CoreServices;});
in
stdenv.mkDerivation rec {
  name = "vmd";
  version = "1.9.3";

  buildInputs = [ gnumake perl libGL fltk tk-8_5 tcl-8_5 my-python-packages which xxd

                  # Linux stuff (TODO: macOS support etc.)
                  xorg.libXinerama xorg.xinput ] ++ (lib.optional withCuda cudatoolkit)
  ++ [ tcsh
       
       # Linux stuff for misc things mostly within the TCL code of vmd:
       bison xterm binutils gnuplot latex2html mafft fasta python27
       last # For `lastal` used in `plugins/mafft.new/mafft-data/core/pairlocalalign.c`
       imagemagick # For `display` command in `vmd-1.9.3/configure` where it says `$def_imageviewer="display %s";`
       
       doxygen graphviz # <-- Not sure if these two are needed

     ] ++ (lib.optional (intelCompilers != {}) intelCompilers)
  ++ [
     ];

  configureFlags = []
                   ++ (lib.splitString " " ("LINUXAMD64 OPENGL OPENGLPBUFFER FLTK TK ACTC " +
                                            (if withCuda then "CUDA " else "") +
                                            "IMD LIBSBALL XINERAMA XINPUT " +
                                            #+ "LIBOPTIX " +   # <-- not supported for now -- it's NVIDIA Optix and there doesn't appear to be a Nix package for it yet.
                                            "LIBOSPRAY LIBTACHYON VRPN NETCDF COLVARS TCL PYTHON PTHREADS NUMPY SILENT ${if (intelCompilers != {}) then "ICC" else "GCC"}")) ++ [

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
$install_bin_dir="'"$out/bin"'";

# Directory where VMD files and executables are installed
$install_library_dir="'"$out/lib"'";' \
      --replace \
      '"plugins' \
      "\"$out/plugins"

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
    substituteInPlace vmd-${version}/configure --replace '$arch_nvcc        = "/usr/local/cuda-8.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$cuda_dir         = "/usr/local/cuda-8.0";' '$cuda_dir         = "${cudatoolkit}";' --replace '$arch_nvcc     = "/usr/local/cuda-4.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$arch_nvcc     = "/usr/local/cuda-5.5/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '$arch_nvcc        = "/usr/local/cuda/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" #--replace '$arch_nvcc        = "/usr/local/cuda-8.0/bin/nvcc";' '$arch_nvcc'"        = \"`which nvcc`\";" --replace '[ ! -x "/bin/csh" ]' 'false'
    substituteInPlace vmd-${version}/configure --replace "/bin/csh" "`which tcsh`" --replace "/bin/sh" "`which sh`"
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
    substituteInPlace plugins/doc/Doxyfile --replace "BIN_ABSPATH            = /usr/local/bin/" "BIN_ABSPATH            = $(dirname "`which doxysearch`")"
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
  '';

  preConfigure = ''
    # Based on https://nixos.wiki/wiki/CUDA
    export CUDA_PATH=${cudatoolkit}
    # export LD_LIBRARY_PATH=${linuxPackages.nvidia_x11}/lib
    export EXTRA_LDFLAGS="-L/lib -L${linuxPackages.nvidia_x11}/lib"
    #export EXTRA_CCFLAGS="-I/usr/include" # <-- ?

    # Build plugins
    cd plugins
    export PLUGINDIR="$out/plugins"
    make -j $NIX_BUILD_CORES distrib

    # Prepare for actual build
    cd ../vmd-${version}
  '';

  postConfigure = ''
    # This is here in case the Makefile gets generated by the configure script.
    # (Assumes we're currently in the `vmd-${version}` folder.)
    echo "out: $out"
    #echo "realpath of Makefile: $(realpath src/Makefile)" # <-- realpath prints `/build/vmd-1.9.3/src/Makefile`
    echo "Note: It's ok if some of these don't match (since they were replaced in the configure script and that seems to generate the Makefile) :"
    substituteInPlace src/Makefile --replace "/usr/local/lib/vmd" "$out/lib" --replace '	if [ ! -d "/usr/local/bin" ]; then \
		$(MAKEDIR) "/usr/local/bin" ; \' "" --replace "/bin/csh" `which tcsh` --replace "/bin/sh" `which sh` --replace "/usr/local/bin" "$out/bin"
    cat src/Makefile
  '';
  
  #configureScript = ''vmd-${version}/configure'';

  dontAddPrefix = true; # `--prefix` in the configure script isn't supported
  
  #makeFlags = ''-C vmd-${version}'';

  # preBuild = ''
  #   cd 
  # '';

  preInstall = ''
    make -j $NIX_BUILD_CORES linux.amd64.opengl

    cd src
    #make veryclean
    make -j $NIX_BUILD_CORES
  '';
}
