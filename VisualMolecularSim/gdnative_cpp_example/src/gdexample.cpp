#include "gdexample.h"

#include "GodotGlobal.hpp"
#include "Math.hpp"

//#include <Viewport.hpp>
//#include <ViewportTexture.hpp>
//#include <Image.hpp>
#include <MultiMeshInstance.hpp>
#include <MultiMesh.hpp>

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

void GDExample::_process(float delta) {
    if (!running) return;
    // if (timePassedTotal + timePassed > flightDuration) {
    //     std::string s = "Simulation finished";
    //     Godot::print(s.c_str());
    //     running = false;
    //     return;
    // }

    // Get list of coords for each atom
    py::object coordsList = trajectory[py::int_(updateNumber)]; // This works only once for some weird reason, if you try grabbing `x[py::int_(0)]` again, it will give an error: `TypeError: Expecting an integer, a slice or a two-tuple of integers and slices as indices.` which appears to be a message generated deep within some pyrex-generated C code: in `pDynamo-1.9.0/pCore-1.9.0/extensions/psource/pCore.Coordinates3.c` (from https://www.pdynamo.org/downloads under `pDynamo-1.9.0`). Possibly related: `pDynamo-1.9.0/pCore-1.9.0/extensions/csource/Coordinates3.c`. So to fix the error, we evaluate the code below:
    using namespace pybind11::literals;

    // Grab MultiMeshInstance
    // Based on https://www.youtube.com/watch?v=XPcSfXsoArQ
    MultiMeshInstance* mmi = (MultiMeshInstance*)get_node("MultiMeshInstance");
    Ref<MultiMesh> mm = mmi->get_multimesh();

    // Loop over all atoms' positions in the coords list
    size_t numAtoms = (py::int_)coordsList.attr("rows");
    mm->set_instance_count(numAtoms);
    auto locals = py::dict("x"_a=coordsList);
    py::int_ _0 = py::int_(0); py::int_ _1 = py::int_(1); py::int_ _2 = py::int_(2);
    py::object vec;
    for (int i = 0; i < numAtoms; i++) {
        locals["i"] = i;
        vec = py::eval(R"(x[i])", py::globals(), locals);
        // `vec` is now the vector for the atom's position!
        locals["vec"] = vec;
        
        // std::string x_ = py::str(x);
        // Godot::print(x_.c_str());

        // Gives `TypeError: Expecting integer not <type 'long'>.`: mm->set_instance_transform(i, Transform(Basis(), Vector3((real_t)(py::float_)vec[_0], (real_t)(py::float_)vec[_1], (real_t)(py::float_)vec[_2])));

        mm->set_instance_transform(i, Transform(Basis(), Vector3((real_t)(py::float_)py::eval("vec[0]", locals), (real_t)(py::float_)py::eval("vec[1]", locals), (real_t)(py::float_)py::eval("vec[2]", locals))));
    }

    updateNumber++;
}
