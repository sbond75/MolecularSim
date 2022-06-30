# https://github.com/NixOS/nixpkgs/blob/nixos-22.05/pkgs/applications/science/molecular-dynamics/lammps/default.nix#L54

{ lib, stdenv, fetchFromGitHub
, libpng, gzip, fftw, blas, lapack
, withMPI ? false
, mpi
, gcc
, pkg-config, callPackage, llvmPackages, bc, cmake, python, git, unixtools, netcdf, gsl, gfortran, eigen, vtk, curl, zstd
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

  passthru = {
    inherit mpi;
    inherit packages;
  };

  buildInputs = [ fftw libpng blas lapack gzip gcc
                  pkg-config llvmPackages.openmp (callPackage ./kim-api.nix {}) bc cmake python git (callPackage ./voro.nix {}) unixtools.xxd netcdf gsl gfortran (callPackage ./ScaFaCoS.nix {}) eigen vtk (callPackage ./LATTE.nix {}) curl zstd
                ]
    ++ (lib.optionals withMPI [ mpi ]);

  cmakeFlags =
    (builtins.map (pkg: "-DPKG_${lib.toUpper pkg}=yes") packages) # Based on https://docs.lammps.org/Build_package.html and https://docs.lammps.org/Build_cmake.html
    ++ [ "../cmake" ] # Sets the location of CMakeLists.txt to be in the folder https://github.com/lammps/lammps/tree/develop/cmake
  ;
  
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
