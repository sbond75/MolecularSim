# https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/applications/science/molecular-dynamics/lammps/default.nix#L54

{ lib, stdenv, fetchFromGitHub
, libpng, gzip, fftw, blas, lapack
, withMPI ? false
, mpi
, gcc
, pkg-config, callPackage, llvmPackages, bc, cmake, python, git, unixtools, netcdf, gsl, gfortran, eigen, vtk, curl, zstd, fetchurl, hdf5, withMKL ? false, mkl, opencl-headers, tbb
}:
let packages = [
      # All packages (from https://github.com/lammps/lammps/blob/7d5fc356fefa1dd31d64b1cc856134b165febb8a/src/Makefile ) :
      # "adios" "asphere" "awpmd" "bocs" "body" "bpm" "brownian" "cg-dna" "cg-sdk" "class2" "colloid"
      # "colvars" "compress" "coreshell" "diffraction" "dipole" "dpd-basic" "dpd-meso" "dpd-react"
      # "dpd-smooth" "drude" "eff" "extra-compute" "extra-dump" "extra-fix" "extra-molecule"
      # "extra-pair" "fep" "gpu" "granular" "h5md" "intel" "interlayer" "kim" "kokkos" "kspace"
      # "latboltz" "latte" "machdyn" "manifold" "manybody" "mc" "mdi" "meam" "mesont" "mgpt" "misc"
      # "ml-hdnnp" "ml-pace" "ml-quip" "ml-rann" "ml-snap" "mofff" "molecule" "molfile" "mpiio" "mscg"
      # "netcdf" "openmp" "opt" "orient" "peri" "plugin" "plumed" "poems" "ptm" "python" "qeq" "qmmm"
      # "qtb" "reaction" "reaxff" "replica" "rigid" "scafacos" "shock" "smtbq" "sph" "spin" "srd"
      # "tally" "uef" "voronoi" "vtk" "yaff" "atc" "dielectric" "electrode" "ml-iap" "phonon"

      # Packages except some with additional library dependencies:
      /*requires ADIOS library from https://github.com/ornladios/ADIOS2 : "adios"*/ "asphere" "awpmd" "bocs" "body" "bpm" "brownian" "cg-dna" "cg-sdk" "class2" "colloid"
      "colvars" "compress" "coreshell" "diffraction" "dipole" "dpd-basic" "dpd-meso" "dpd-react"
      "dpd-smooth" "drude" "eff" "extra-compute" "extra-dump" "extra-fix" "extra-molecule"
      "extra-pair" "fep" "gpu" "granular" "h5md" "intel" "interlayer" "kim" "kokkos" "kspace"
      "latboltz" "latte" "machdyn" "manifold" "manybody" "mc" "mdi" "meam" "mesont" "mgpt" "misc"
      "ml-hdnnp" "ml-pace" /*requires QUIP library from https://github.com/libAtoms/QUIP : "ml-quip"*/ "ml-rann" "ml-snap" "mofff" "molecule" "molfile" "mpiio" "mscg"
      "netcdf" "openmp" "opt" "orient" "peri" "plugin" "plumed" "poems" "ptm" "python" "qeq" "qmmm"
      "qtb" "reaction" "reaxff" "replica" "rigid" "scafacos" "shock" "smtbq" "sph" "spin" "srd"
      "tally" "uef" "voronoi" "vtk" "yaff" "atc" "dielectric" "electrode" "ml-iap" "phonon"
    ];
    lammps_includes = "-DLAMMPS_EXCEPTIONS -DLAMMPS_GZIP -DLAMMPS_MEMALIGN=64";
in
stdenv.mkDerivation rec {
  # LAMMPS has weird versioning converted to ISO 8601 format
  version = "stable_23Jun2022";
  pname = "lammps";

  src = fetchFromGitHub {
    owner = "lammps";
    repo = "lammps";
    rev = version;
    sha256 = "061mkvj5pp8p1na5qk9x7wcgpx8hjnclflzk1q0a8rvs1kilpkv2";
  };
  
  # "PACE evaluator library"
  src_lammpsUserPACE = fetchFromGitHub {
    owner = "ICAMS";
    repo = "lammps-user-pace";
    rev = "v.2021.10.25.fix2";
    sha256 = "00ldmxakw2pba2d0fw96yf0q5v449d4kv0pbjkyv0975w8664qj6";
  };

  # Try: `cat src/*/potentials.txt` in the lammps repo root to see which of these "potentials" should be added here:
  # In the current case, this outputs (from `src/MESONT/potentials.txt`) :
  # # list of potential files to be fetched when this package is installed
  # # potential file  md5sum
  # C_10_10.mesocnt 028de73ec828b7830d762702eda571c1
  # TABTP_10_10.mesont 744a739da49ad5e78492c1fc9fd9f8c1
  C_10_10 = fetchurl rec {
    sha256 = "1v2qljljmxmk3vnx31pc9zzqxmazg3s459fj647mxcd0kz1mdlx7";
    name = "C_10_10.mesocnt";
    url = "https://download.lammps.org/potentials/${name}.028de73ec828b7830d762702eda571c1";
  };
  TABTP_10_10 = fetchurl rec {
    sha256 = "1ba33fsy6qlp11hhpgha92p704rl4schk7hx73n43yi559pv69zr";
    name = "TABTP_10_10.mesont";
    url = "https://download.lammps.org/potentials/${name}.744a739da49ad5e78492c1fc9fd9f8c1";
  };

  # More "external projects"
  src_openclLoader = fetchTarball {
    url = "https://download.lammps.org/thirdparty/opencl-loader-2022.01.04.tar.gz";
    sha256 = "19cb3vghf0vrbph6jyirz295hz67x3by0fb8h9qfxi07x9fxbman";
  };

  
  passthru = {
    inherit mpi;
    inherit packages;
  };

  buildInputs = [ fftw libpng blas lapack gzip gcc
                  pkg-config llvmPackages.openmp (callPackage ./kim-api.nix {}) bc cmake python git (callPackage ./voro.nix {}) unixtools.xxd netcdf gsl gfortran (callPackage ./ScaFaCoS.nix {}) eigen vtk (callPackage ./LATTE.nix {}) curl zstd (callPackage ./MSCG.nix {}) hdf5 (lib.optional withMKL mkl) opencl-headers tbb
                ]
    ++ (lib.optionals withMPI [ mpi ]);

  cmakeFlags =
    (builtins.map (pkg: "-DPKG_${lib.toUpper pkg}=yes") packages) # Based on https://docs.lammps.org/Build_package.html and https://docs.lammps.org/Build_cmake.html
    ++ [ "../cmake" ] # Sets the location of CMakeLists.txt to be in the folder https://github.com/lammps/lammps/tree/develop/cmake
  ;

  patchPhase = ''
    substituteInPlace cmake/Modules/Packages/MSCG.cmake --replace \
      "if(MSGC_FOUND)" \
      "if(TRUE)"

    substituteInPlace cmake/Modules/Packages/ML-PACE.cmake --replace \
      '# download library sources to build folder
file(DOWNLOAD ''${PACELIB_URL} ''${CMAKE_BINARY_DIR}/libpace.tar.gz EXPECTED_HASH MD5=''${PACELIB_MD5}) #SHOW_PROGRESS

# uncompress downloaded sources
execute_process(
  COMMAND ''${CMAKE_COMMAND} -E remove_directory lammps-user-pace*
  COMMAND ''${CMAKE_COMMAND} -E tar xzf libpace.tar.gz
  WORKING_DIRECTORY ''${CMAKE_BINARY_DIR}
)
get_newest_file(''${CMAKE_BINARY_DIR}/lammps-user-pace-* lib-pace)' \
      "set(lib-pace ${src_lammpsUserPACE})"

    substituteInPlace cmake/Modules/LAMMPSUtils.cmake --replace \
      '# fetch missing potential files
function(FetchPotentials pkgfolder potfolder)
  if(EXISTS "''${pkgfolder}/potentials.txt")
    file(STRINGS "''${pkgfolder}/potentials.txt" linelist REGEX "^[^#].")
    foreach(line ''${linelist})
      string(FIND ''${line} " " blank)
      math(EXPR plusone "''${blank}+1")
      string(SUBSTRING ''${line} 0 ''${blank} pot)
      string(SUBSTRING ''${line} ''${plusone} -1 sum)
      if(EXISTS ''${LAMMPS_POTENTIALS_DIR}/''${pot})
        file(MD5 "''${LAMMPS_POTENTIALS_DIR}/''${pot}" oldsum)
      endif()
      if(NOT sum STREQUAL oldsum)
        message(STATUS "Checking external potential ''${pot} from ''${LAMMPS_POTENTIALS_URL}")
        file(DOWNLOAD "''${LAMMPS_POTENTIALS_URL}/''${pot}.''${sum}" "''${CMAKE_BINARY_DIR}/''${pot}"
          EXPECTED_HASH MD5=''${sum} SHOW_PROGRESS)
        file(COPY "''${CMAKE_BINARY_DIR}/''${pot}" DESTINATION ''${LAMMPS_POTENTIALS_DIR})
      endif()
    endforeach()
  endif()
endfunction(FetchPotentials)' \
      'function(FetchPotentials pkgfolder potfolder)
endfunction(FetchPotentials)'

    substituteInPlace cmake/CMakeLists.txt --replace \
      'install(DIRECTORY ''${LAMMPS_POTENTIALS_DIR} DESTINATION ''${LAMMPS_INSTALL_DATADIR})' \
      'file(MAKE_DIRECTORY ''${LAMMPS_INSTALL_DATADIR}/potentials)
install(FILES ${C_10_10} ${TABTP_10_10} DESTINATION ''${LAMMPS_INSTALL_DATADIR}/potentials)'

    substituteInPlace cmake/Modules/ExternalCMakeProject.cmake --replace \
      'file(MAKE_DIRECTORY ''${CMAKE_BINARY_DIR}/_deps/src)
  message(STATUS "Downloading ''${url}")
  file(DOWNLOAD ''${url} ''${CMAKE_BINARY_DIR}/_deps/''${archive} EXPECTED_HASH MD5=''${hash} SHOW_PROGRESS)
  message(STATUS "Unpacking and configuring ''${archive}")
  execute_process(COMMAND ''${CMAKE_COMMAND} -E tar xzf ''${CMAKE_BINARY_DIR}/_deps/''${archive}
    WORKING_DIRECTORY ''${CMAKE_BINARY_DIR}/_deps/src)
  file(GLOB TARGET_SOURCE "''${CMAKE_BINARY_DIR}/_deps/src/''${basedir}*")
  list(LENGTH TARGET_SOURCE _num)
  if(_num GREATER 1)
    message(FATAL_ERROR "Inconsistent ''${target} library sources. "
      "Please delete ''${CMAKE_BINARY_DIR}/_deps/src and re-run cmake")
  endif()
  file(REMOVE_RECURSE ''${CMAKE_BINARY_DIR}/_deps/''${target}-src)
  file(RENAME ''${TARGET_SOURCE} ''${CMAKE_BINARY_DIR}/_deps/''${target}-src)' \
      "" \
      --replace \
      "''${CMAKE_BINARY_DIR}/_deps/''${target}-src" \
      "${src_openclLoader}"
  '';
  
  # configurePhase = ''
  #   cd src
  #   for pack in ${lib.concatStringsSep " " packages}; do make "yes-$pack" SHELL=$SHELL; done
  # '';

  # # Must do manual build due to LAMMPS requiring a seperate build for
  # # the libraries and executable. Also non-typical make script
  # buildPhase = ''
  #   make mode=exe ${if withMPI then "mpi" else "serial"} SHELL=$SHELL LMP_INC="${lammps_includes}" FFT_PATH=-DFFT_FFTW3 FFT_LIB=-lfftw3 JPG_LIB=-lpng
  #   make mode=shlib ${if withMPI then "mpi" else "serial"} SHELL=$SHELL LMP_INC="${lammps_includes}" FFT_PATH=-DFFT_FFTW3 FFT_LIB=-lfftw3 JPG_LIB=-lpng
  # '';

  # installPhase = ''
  #   mkdir -p $out/bin $out/include $out/lib
  #   cp -v lmp_* $out/bin/
  #   cp -v *.h $out/include/
  #   cp -v liblammps* $out/lib/
  # '';

  meta = with lib; {
    description = "Classical Molecular Dynamics simulation code";
    longDescription = ''
      LAMMPS is a classical molecular dynamics simulation code designed to
      run efficiently on parallel computers. It was developed at Sandia
      National Laboratories, a US Department of Energy facility, with
      funding from the DOE. It is an open-source code, distributed freely
      under the terms of the GNU Public License (GPL).
      '';
    homepage = "https://lammps.sandia.gov";
    license = licenses.gpl2Plus;
    platforms = platforms.linux ++ platforms.darwin;
    maintainers = [ maintainers.costrouc ];
  };
}
