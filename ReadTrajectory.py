"""Example 16."""

from Definitions import *
from Util import *

# . Define the energy models.
mmModel = MMModelOPLS ( "bookSmallExamples" )
nbModel = NBModelFull ( )

# . Generate the molecule.
molecule = MOLFile_ToSystem ( os.path.join ( molPath, "bala_c7eq.mol" ) )
molecule.DefineMMModel ( mmModel )
molecule.DefineNBModel ( nbModel )

# Read in the existing trajectory
trajectory = SystemGeometryTrajectory ( os.path.join ( scratchPath, "bala_c7eq.trj" ), molecule, mode = "r" )

#startREPL(globals=globals(), locals=locals())
