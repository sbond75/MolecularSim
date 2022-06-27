#include "gdexample.h"

#include "Basis.hpp"
#include "GodotGlobal.hpp"
#include "Math.hpp"

//#include <Viewport.hpp>
//#include <ViewportTexture.hpp>
//#include <Image.hpp>
#include <MultiMeshInstance.hpp>
#include <MultiMesh.hpp>
#include <RandomNumberGenerator.hpp>

#include <cstdlib>

#include <algorithm> // std::min

#include <pybind11/embed.h>
#include <pybind11/stl.h>

using namespace godot;

// https://en.cppreference.com/w/cpp/thread/call_once
std::once_flag flagInitPython;
void initPython_do_once()
{
    std::call_once(flagInitPython, [](){
        Godot::print("Initializing Python...");
        py::initialize_interpreter();
        std::atexit([](){
            Godot::print("Deinitializing Python...");
            py::finalize_interpreter();
            Godot::print("Deinitialized Python"); /*TODO: fflush(stdout) of some sort should be here after this print() ideally*/
        });
        Godot::print("Initialized Python"); /*TODO: fflush(stdout) of some sort should be here after this print() ideally*/
        
        // Hack to fix PYTHONPATH
        py::exec(R"(from __future__ import print_function
import sys
print('sys.path:',sys.path)
import os
p="/nix/store/41prvfp9n0x56xvi5s4xagshwqj8cyj9-python-2.7.18-env/lib/python2.7/site-packages"
assert(os.path.exists(p)) # If this assertion fails, check what is present in Nix `python2 -c 'import sys; print(sys.path)'` but missing in the line starting with `sys.path:` that was printed above.
sys.path.append(p))"
                 , py::globals());
    });
}

void GDExample::_register_methods() {
    register_method("_process", &GDExample::_process);
}

GDExample::GDExample()
{
    initPython_do_once();

    rt = py::module_::import("ReadTrajectory");
    trajectory = rt.attr("trajectory");
    molecule = rt.attr("molecule");
}

GDExample::~GDExample() {
    // add your cleanup here
}

void GDExample::initSim(double timeSkip_) {
    // initialize any variables here
    currentRowIndex = 0;
    timePassedTotal += timePassed;
    timePassed = 0.0;
    timeSkip = 0.0;
    running = true;
    updateNumber = 0;
    
    // Configurable //
    timeScale = 0.80; //1;//15; //90; //5; //0.5; //0.1;
    posScale = 1; //0.00001; //0.001;
    // //
    
    std::string s = "timeSkip: " + std::to_string(timeSkip);
    Godot::print(s.c_str());
    s = "currentRowIndex: " + std::to_string(currentRowIndex);
    Godot::print(s.c_str());
}

void GDExample::_init() {
    originalTransform = get_transform();
    timePassed = 0.0;
    initSim();
}

double GDExample::currentTime() const {
    return timePassed + timeSkip;
}

// void GDExample::_input(Variant event) {
//     Ref<InputEventKey> btn = event;
//     if (btn->is_pressed() && btn->get_scancode() == GlobalConstants::KEY_R) {
//         timeScale += 0.05;
//     }
// }

inline Vector3 midpoint(Vector3 a, Vector3 b) {
    return {(a.x + b.x) * (real_t)0.5, (a.y + b.y) * (real_t)0.5, (a.z + b.z) * (real_t)0.5};
}

// https://stackoverflow.com/questions/18558910/direction-vector-to-rotation-matrix
Basis makeRotationDir(const Vector3& direction, const Vector3& up = Vector3::UP) {
    Vector3 xaxis = up.cross(direction);
    xaxis.normalize();

    Vector3 yaxis = direction.cross(xaxis);
    yaxis.normalize();

    Vector3 column1, column2, column3;
    column1.x = xaxis.x;
    column1.y = yaxis.x;
    column1.z = direction.x;

    column2.x = xaxis.y;
    column2.y = yaxis.y;
    column2.z = direction.y;

    column3.x = xaxis.z;
    column3.y = yaxis.z;
    column3.z = direction.z;

    return Basis(column1, column2, column3);
}

static const Vector3 X_AXIS = Vector3::RIGHT;
static const Vector3 Y_AXIS = Vector3::UP;
static const Vector3 Z_AXIS = Vector3::BACK;
// https://stackoverflow.com/questions/1171849/finding-quaternion-representing-the-rotation-from-one-vector-to-another/1171995#1171995
Vector3 orthogonal(Vector3 v)
{
    float x = abs(v.x);
    float y = abs(v.y);
    float z = abs(v.z);

    Vector3 other = x < y ? (x < z ? X_AXIS : Z_AXIS) : (y < z ? Y_AXIS : Z_AXIS);
    return v.cross(other);
}
Quat get_rotation_between(Vector3 u, Vector3 v)
{
  // It is important that the inputs are of equal length when
  // calculating the half-way vector.
  u.normalize();
  v.normalize();

  // Unfortunately, we have to check for when u == -v, as u + v
  // in this case will be (0, 0, 0), which cannot be normalized.
  if (u == -v)
  {
    // 180 degree rotation around any orthogonal vector
      return Quat(orthogonal(u).normalized(), 0);
  }

  Vector3 half = (u + v).normalized();
  return Quat(u.cross(half), u.dot(half));
}

void GDExample::_process(float delta) {
    if (!running) return;
    // if (timePassedTotal + timePassed > flightDuration) {
    //     std::string s = "Simulation finished";
    //     Godot::print(s.c_str());
    //     running = false;
    //     return;
    // }
    
    size_t numFrames = (py::int_)trajectory.attr("__len__")();
    if (updateNumber >= numFrames) {
        Godot::print("Simulation finished");
        running = false;
        return;
    }

    // Get list of coords for each atom
    py::object coordsList = trajectory[py::int_(updateNumber)]; // This works only once for some weird reason, if you try grabbing `x[py::int_(0)]` again, it will give an error: `TypeError: Expecting an integer, a slice or a two-tuple of integers and slices as indices.` which appears to be a message generated deep within some pyrex-generated C code: in `pDynamo-1.9.0/pCore-1.9.0/extensions/psource/pCore.Coordinates3.c` (from https://www.pdynamo.org/downloads under `pDynamo-1.9.0`). Possibly related: `pDynamo-1.9.0/pCore-1.9.0/extensions/csource/Coordinates3.c`. So to fix the error, we evaluate the code below:
    using namespace pybind11::literals;

    // Grab MultiMeshInstance
    // Based on https://www.youtube.com/watch?v=XPcSfXsoArQ
    MultiMeshInstance* mmi = (MultiMeshInstance*)get_node("Molecules");
    Ref<MultiMesh> mm = mmi->get_multimesh();

    // Loop over all atoms' positions in the coords list
    size_t numAtoms = (py::int_)coordsList.attr("rows");
    assert((ssize_t)numAtoms >= 0); // Assert ">= 0"
    mm->set_instance_count(numAtoms);
    auto locals = py::dict("x"_a=coordsList);
    py::int_ _0 = py::int_(0); py::int_ _1 = py::int_(1); py::int_ _2 = py::int_(2);
    py::object vec;
    for (size_t i = 0; i < numAtoms; i++) {
        locals["i"] = i;
        vec = py::eval(R"(x[i])", py::globals(), locals);
        // `vec` is now the vector for the atom's position!
        locals["vec"] = vec;
        
        // std::string x_ = py::str(x);
        // Godot::print(x_.c_str());

        // Gives `TypeError: Expecting integer not <type 'long'>.`: mm->set_instance_transform(i, Transform(Basis(), Vector3((real_t)(py::float_)vec[_0], (real_t)(py::float_)vec[_1], (real_t)(py::float_)vec[_2])));

        mm->set_instance_transform(i, Transform(Basis(), Vector3((real_t)(py::float_)py::eval("vec[0]", locals), (real_t)(py::float_)py::eval("vec[1]", locals), (real_t)(py::float_)py::eval("vec[2]", locals))));
    }

    // Grab bonds //
    
    // Grab MultiMeshInstance
    mmi = (MultiMeshInstance*)get_node("Bonds");
    mm = mmi->get_multimesh();

    py::object bonds = molecule.attr("connectivity").attr("bonds");
    size_t numBonds = (py::int_)bonds.attr("__len__")();
    assert((ssize_t)numBonds >= 0); // Assert ">= 0"
    mm->set_instance_count(numBonds);
    locals["bonds"] = bonds;
    py::object bond;
    std::pair<size_t, size_t> bondAtomIndices;
    for (size_t i = 0; i < numBonds; i++) {
        locals["i"] = i;
        bond = py::eval(R"(bonds[i])", py::globals(), locals);
        bondAtomIndices = {(size_t)(py::int_)bond.attr("i"), (size_t)(py::int_)bond.attr("j")};
        assert((ssize_t)bondAtomIndices.first >= 0 && (ssize_t)bondAtomIndices.second >= 0); // Assert ">= 0"
        assert(bondAtomIndices.first < numAtoms && bondAtomIndices.second < numAtoms); // Assert in bounds of the atom coords list

        // Grab the atom coords for this bond's ends
        locals["i"] = bondAtomIndices.first;
        locals["j"] = bondAtomIndices.second;
        py::tuple atomCoords__ = (py::tuple)py::eval(R"((x[i], x[j]))", py::globals(), locals);
        std::pair<py::object, py::object> atomCoords_ = {atomCoords__[0], atomCoords__[1]};
        
        locals["vec1"] = atomCoords_.first;
        locals["vec2"] = atomCoords_.second;
        std::pair<Vector3, Vector3> atomCoords = {
            Vector3((real_t)(py::float_)py::eval("vec1[0]", locals), (real_t)(py::float_)py::eval("vec1[1]", locals), (real_t)(py::float_)py::eval("vec1[2]", locals)), Vector3((real_t)(py::float_)py::eval("vec2[0]", locals), (real_t)(py::float_)py::eval("vec2[1]", locals), (real_t)(py::float_)py::eval("vec2[2]", locals))
        };

        Vector3 atomsVec = atomCoords.second - atomCoords.first; // The vector between the atoms
        auto x = atomsVec.x, y = atomsVec.y, z = atomsVec.z;
        // https://community.khronos.org/t/converting-a-3d-vector-into-three-euler-angles/49889/3
        // "Let r = radius, t = angle on x-y plane, & p = angle off of z-axis."
        auto r = sqrt(x*x + y*y + z*z); // radius
        auto t = atan(y/x); // yaw (our convention here is chosen for this to be: about z axis)
        auto p = acos(z/r); // pitch (convention chosen: about x axis)
        real_t roll = 0; // roll (convention chosen: about y axis)
        Vector3 bondDirection = atomsVec.normalized();
        
        auto transform = Transform().looking_at(bondDirection, Vector3::UP); // Following tip on https://godotengine.org/qa/77346/moving-and-rotating-trees-in-multimesh : "first rotate then reposition"
        transform.rotate(transform.basis.x, M_PI/2);
        transform.origin = midpoint(atomCoords.first, atomCoords.second);
        mm->set_instance_transform(i, transform);
        
        mm->set_instance_custom_data(i, Color(r, 0, 0, 0)); // Says Color() but really isn't -- it becomes a per-instance `INSTANCE_CUSTOM` variable within the shader. This is a silly function in Godot, should be improved on their side to support variable amounts of data instead of only 4 or nothing.
    } 
    // //
    

    updateNumber++;
}
