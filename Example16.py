"""Example 16."""

from Definitions import *
from Util import *

# . Define the energy models.
mmModel = MMModelOPLS ( "bookSmallExamples" )
nbModel = NBModelFull ( )

# . Generate the molecule.
#moleculeFileName="bala_c7eq.mol"
moleculeFileName="r22.mol" # How I grabbed it: https://pubchem.ncbi.nlm.nih.gov/compound/Chlorodifluoromethane#section=3D-Conformer and then click download -> SDF. Then convert this file using http://www.cheminfo.org/Chemistry/Cheminformatics/FormatConverter/index.html and select SDF as the input format. "Untyped atoms" [maybe?] means the definition isn't in `/nix/store/x165imivrma61v7y9c9jc7d2c78dfpil-pDynamo2-1.9.0/parameters/forceFields/opls/bookSmallExamples/atomTypes.yaml` (including the "Charge" attribute -- all the "Parameter Values" are labelled right above in the "Parameter Fields" section -- so convenient.
# More info on the MOL format: https://chem.libretexts.org/Courses/University_of_Arkansas_Little_Rock/ChemInformatics_(2017)%3A_Chem_4399_5399/2.2%3A_Chemical_Representations_on_Computer%3A_Part_II/2.2.2%3A_Anatomy_of_a_MOL_file
#molecule = MOLFile_ToSystem ( os.path.join ( molPath, moleculeFileName ) )
molecule = MOLFile_ToSystem ( os.path.join ( moleculeFileName ) )
molecule.DefineMMModel ( mmModel )
molecule.DefineNBModel ( nbModel )
molecule.Summary ( )
molecule.Energy  ( )

# . Optimization.
ConjugateGradientMinimize_SystemGeometry ( molecule                    ,
                                           maximumIterations    = 2000 ,
                                           logFrequency         =  100 ,
                                           rmsGradientTolerance =  0.1 )

# . Define a random number generator in a given state.
normalDeviateGenerator = NormalDeviateGenerator.WithRandomNumberGenerator ( RandomNumberGenerator.WithSeed ( 175189 ) )

# . Heating.
VelocityVerletDynamics_SystemGeometry ( molecule                             ,
                                        logFrequency              =      100 ,
                                        normalDeviateGenerator    = normalDeviateGenerator ,
                                        steps                     =     1000 ,
                                        timeStep                  =    0.001 ,
                                        temperatureScaleFrequency =      100 ,
                                        temperatureScaleOption    = "linear" ,
                                        temperatureStart          =     10.0 ,
                                        temperatureStop           =    300.0 )

# . Equilibration.
VelocityVerletDynamics_SystemGeometry ( molecule                               ,
                                        logFrequency              =        500 ,
                                        steps                     =       5000 ,
                                        timeStep                  =      0.001 ,
                                        temperatureScaleFrequency =        100 ,
                                        temperatureScaleOption    = "constant" ,
                                        temperatureStart          =      300.0 )

# . Data-collection.
trajectory = SystemGeometryTrajectory ( os.path.join ( scratchPath, os.path.splitext(moleculeFileName)[0] + ".trj" ), molecule, mode = "w" )
VelocityVerletDynamics_SystemGeometry ( molecule             ,
                                        logFrequency =   500 ,
                                        steps        = 100000 ,
                                        timeStep     = 0.001 ,
                                        trajectories = [ ( trajectory, 100 ) ] )

startREPL(globals=globals(), locals=locals())

# tip: renderer on trajectory[0][0][0] etc.
