#include <Python.h>   // Required to embed Python
#include <iostream>   // For debugging output using cerr
#include <cstdlib>    // For malloc()/free()
#include <svdpi.h>    // For SV DPI types like svOpenArrayHandle // It defines C types, constants, and functions needed to interact with SV from C/C++.
using namespace std;  // Avoid repeating std::


// Track Python state across calls
static bool python_initialized = false;

// Initialize Python only once : Utility: Initialize Python & append current path
static bool init_python() {
    if (python_initialized) {
        return true; // Skip if already done
    }
    python_initialized = true;

    Py_SetPythonHome(L"C:\\Users\\muham\\AppData\\Local\\Programs\\Python\\Python313");// Force Python to use the correct installation
    Py_Initialize(); // 1. Start Python interpreter
    PyRun_SimpleString("import sys; sys.path.append('.')");
    cout << "[DPI] Python initialized.\n";
    return true;
}

// Finalize Python (only if it was initialized) :  Utility: Clean up Python
static void finalize_python() {
    if (!python_initialized) return;
    Py_Finalize(); // 4. Finalize Python interpreter- Shutdown Python
    python_initialized = false;
    cout << "[DPI] Python finalized.\n";
}






// Generic caller: Takes Python module, function, args tuple, returns list of bytes into SV array
static int call_python_list_func(const char* module_name, const char* func_name,
                                 PyObject* args, svOpenArrayHandle sv_bytes, int *out_len) 
{
    
    
    // 2. Import Python module (packet_generator.py file) & return a pointer to Python object
    PyObject* mod = PyImport_ImportModule(module_name);  // The * appears because PyObject instances (tuples etc.) created live on the heap in python; C uses PyObject* to reference managed Python objects.
    if (!mod) { PyErr_Print(); cerr << "Import failed\n"; return -1; }

    // Get function
    PyObject* func = PyObject_GetAttrString(mod, func_name);
    if (!func || !PyCallable_Check(func)) {
        PyErr_Print(); cerr << "Function not callable\n";
        Py_DECREF(mod); return -1;
    }

    // 3. Calls Python function from C++. tuple is unpacked into the parameters hwsrc, psrc, hwdst, pdst in the Python function create_<abc>_frame(...)
    // The function's return value (Python object (list) ) will be referenced by the pointer 'result' (type PyObject*).
    PyObject* result = PyObject_CallObject(func, args);
    
    // Clean up temp Python references by decrementing refcounts to avoid memory leaks
    Py_DECREF(args); Py_DECREF(func); Py_DECREF(mod);

    // Check result is a list of bytes
    if (!result || !PyList_Check(result)) { // PyCallable_Check(func) ensures that the attribute is actually callable (a function/method) before you call it.
        PyErr_Print(); cerr << "Expected list from Python\n";
        // If it’s null, it prints an error, cleans up Python references, finalizes the interpreter, and returns -1 to SV
        Py_XDECREF(result); return -1;
    }


     // Allocate C-style byte array to return to SV
    int len = PyList_Size(result); // Get the size of the Python list 'result' and store it in 'len'
    *out_len = len; // Returns its size to SV by storing 'len' into '*out_len' so SystemVerilog knows the array size.
    
    
    // Access SV array data pointer
    unsigned char* sv_data = (unsigned char*)svGetArrayPtr(sv_bytes);
    // svGetArrayPtr(sv_bytes) is a DPI function that gives you a direct pointer to the memory of the SystemVerilog array passed in (sv_bytes).
    // (unsigned char*) casts that generic pointer to a unsigned char* so C++ can treat it as a byte array.
    // Now sv_data points to SV’s actual array storage in simulator memory — so you can write into it from C++.
    if (!sv_data) {
        cerr << "SV array pointer is null!\n"; Py_DECREF(result); return -1;
    }

    // Copy each list item from python (converted to unsigned char) into the SV array.
    // DEBUG: Show bytes copied into SV array in one line
    cout << "[DEBUG_C++] Python list returned: [";
    for (int i = 0; i < len; ++i) {
        sv_data[i] = (unsigned char)PyLong_AsLong(PyList_GetItem(result, i));
        cout << (int)sv_data[i];
        if (i < len - 1) cout << ", ";
    }
    cout << "]" << endl;
    cout << "-----------------------------------------------------------------------------------------------------"<<endl;
    
    
    Py_DECREF(result);
    return 0;
    
}







// ======================= Specific DPI Functions =======================

// ARP
// extern "C": Allows SystemVerilog to link to C++
// call_create_arp_frame will call the Python function create_arp_frame to get list and return a byte array to SV
// __declspec`ification`(dllexport) tells the compiler to export this function from the DLL so that external programs (like SystemVerilog via DPI) can find and call it.
extern "C" __declspec(dllexport) int call_create_arp_frame(
    const char* hwsrc, const char* psrc,
    const char* hwdst, const char* pdst,
    svOpenArrayHandle sv_bytes, int *out_len)// `svOpenArrayHandle` is a special handle type that represents a SystemVerilog open array passed into C++.
{                                            //  so C++ code can read/write elements in SV array without knowing its exact size at compile time.

    init_python();
    // Pack C strings into a Python tuple (4 string args)
    PyObject* args = Py_BuildValue("(ssss)", hwsrc, psrc, hwdst, pdst);
    int ret = call_python_list_func("packet_generator", "create_arp_frame", args, sv_bytes, out_len);
    finalize_python();
    return ret;
}

// Ethernet
extern "C" __declspec(dllexport) int call_create_eth_frame(
    const char* src_mac, const char* dst_mac, unsigned short eth_type,
    svOpenArrayHandle sv_bytes, int *out_len) {

    init_python();
    PyObject* args = Py_BuildValue("(ssh)", src_mac, dst_mac, eth_type);
    int ret = call_python_list_func("packet_generator", "create_eth_frame", args, sv_bytes, out_len);
    finalize_python();
    return ret;
}

// IP
extern "C" __declspec(dllexport) int call_create_ip_header(
    const char* src_ip, const char* dst_ip, int proto,
    svOpenArrayHandle sv_bytes, int *out_len) {

    init_python();
    PyObject* args = Py_BuildValue("(ssi)", src_ip, dst_ip, proto);
    int ret = call_python_list_func("packet_generator", "create_ip_header", args, sv_bytes, out_len);
    finalize_python();
    return ret;
}

// UDP
extern "C" __declspec(dllexport) int call_create_udp_header(
    int sport, int dport, int payload_len,
    svOpenArrayHandle sv_bytes, int *out_len) {

    init_python();
    PyObject* args = Py_BuildValue("(iii)", sport, dport, payload_len);
    int ret = call_python_list_func("packet_generator", "create_udp_header", args, sv_bytes, out_len);
    finalize_python();
    return ret;
}








