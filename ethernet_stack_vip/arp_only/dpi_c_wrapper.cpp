#include <Python.h>   // Required to embed Python
#include <iostream>   // For debugging output using cerr
#include <cstdlib>    // For malloc()/free()
#include <svdpi.h>    // For SV DPI types like svOpenArrayHandle // It defines C types, constants, and functions needed to interact with SV from C/C++.
using namespace std;  // Avoid repeating std::







// extern "C": Allows SystemVerilog to link to C++
// call_create_arp_frame will call the Python function create_arp_frame to get list and return a byte array to SV
// __declspec`ification`(dllexport) tells the compiler to export this function from the DLL so that external programs (like SystemVerilog via DPI) can find and call it.
extern "C" __declspec(dllexport) int call_create_arp_frame(
    const char* hwsrc,
    const char* psrc,
    const char* hwdst,
    const char* pdst,
    svOpenArrayHandle sv_bytes, // `svOpenArrayHandle` is a special handle type that represents a SystemVerilog open array passed into C++.
                               //so C++ code can read/write elements in SV array without knowing its exact size at compile time.
    int *out_len
)
{
    // Force Python to use the correct installation
    Py_SetPythonHome(L"C:\\Users\\muham\\AppData\\Local\\Programs\\Python\\Python313");
                                                    
    // 1. Start Python interpreter
    Py_Initialize();
    PyRun_SimpleString("import sys; sys.path.append('.')");// Add current dir to Python path so we can find our .py file

    // 2. Import Python module (arp_function.py file) & return a pointer to Python object
    PyObject* mod = PyImport_ImportModule("arp_function"); // The * appears because PyObject instances (tuples etc.) created live on the heap in python; C uses pointers as handles to those Python objects
    if (!mod) { PyErr_Print(); cerr << "Import failed\n"; Py_Finalize(); return -1; }

    // Get function from module
    PyObject* func = PyObject_GetAttrString(mod, "create_arp_frame");
    if (!func || !PyCallable_Check(func)) { // PyCallable_Check(func) ensures that the attribute is actually callable (a function/method) before you call it.
        PyErr_Print(); cerr << "Function not callable\n";
        Py_DECREF(mod); Py_Finalize(); return -1;
    }

    // Pack C strings into a Python tuple (4 string args) 
    PyObject* args = Py_BuildValue("(ssss)", hwsrc, psrc, hwdst, pdst); 
    cout << "-----------------------------------------------------------------------------------------------------"<<endl;
    cout << "[DEBUG_C++] packet parameters being passed from C++ to Python for packet generation!" << endl;

    // 3. Calls Python function from C++. tuple is unpacked into the parameters hwsrc, psrc, hwdst, pdst in the Python function create_arp_frame(...)
    // The function's return value (Python object (list) ) will be referenced by the pointer 'result' (type PyObject*).
    PyObject* result = PyObject_CallObject(func, args);

    // Clean up temp Python references by decrementing refcounts to avoid memory leaks
    Py_DECREF(args); Py_DECREF(func); Py_DECREF(mod);

    // Check result is a list of bytes
    if (!result || !PyList_Check(result)) {
        PyErr_Print(); cerr << "Expected list from Python\n";
        //If it’s null, it prints an error, cleans up Python references, finalizes the interpreter, and returns -1 to SV
        Py_XDECREF(result); Py_Finalize(); return -1;
    }


    // DEBUG: Print Python list in C++
    cout << "[DEBUG_C++] Packet in Python list format returned to C++: [";
    for (int i = 0; i < PyList_Size(result); ++i) {
        long val = PyLong_AsLong(PyList_GetItem(result, i));
        cout << val;
        if (i < PyList_Size(result) - 1) cout << ", ";
    }
    cout << "]" << endl;

    // Allocate C-style byte array to return to SV
    int len = PyList_Size(result); // Get the size of the Python list 'result' and store it in 'len'
    *out_len = len; // Returns its size to SV by storing 'len' into '*out_len' so SystemVerilog knows the array size.
    
    // Access SV array data pointer
    unsigned char* sv_data = (unsigned char*)svGetArrayPtr(sv_bytes);
    // svGetArrayPtr(sv_bytes) is a DPI function that gives you a direct pointer to the memory of the SystemVerilog array passed in (sv_bytes).
    // (unsigned char*) casts that generic pointer to a unsigned char* so C++ can treat it as a byte array.
    // Now sv_data points to SV’s actual array storage in simulator memory — so you can write into it from C++.
    if (!sv_data) {
        cerr << "SV array pointer is null!\n"; Py_DECREF(result); Py_Finalize(); return -1;
    }

    // Copy each list item from python (converted to unsigned char) into the SV array.
    // DEBUG: Show bytes copied into SV array in one line
    cout << "[DEBUG_C++] Copied bytes to SV array: [";
    for (int i = 0; i < len; ++i) {
        sv_data[i] = (unsigned char)PyLong_AsLong(PyList_GetItem(result, i));
        cout << (int)sv_data[i];
        if (i < len - 1) cout << ", ";
    }
    cout << "]" << endl;
    cout << "-----------------------------------------------------------------------------------------------------"<<endl;

    Py_DECREF(result);

    // 4. Finalize Python interpreter
    Py_Finalize();  // Shut down Python
     
    return 0;
}

