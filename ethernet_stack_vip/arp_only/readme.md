## DLL (Dynamic Link Library) Concept use case 

1.  write C/C++ functions (like `call_create_arp_frame`) and mark them with  `extern "C" __declspec(dllexport)` so they can be found outside the code.

2. You compile those functions into a DLL using cl (MSVC compiler).
3. The DLL is just a file containing machine code + an “export table” listing available functions.
4. SystemVerilog DPI knows about these functions because we declare them in SV with
`import "DPI-C" function ...;`
5. When the simulation starts, the simulator (like QuestaSim) loads your DLL into memory.
The SV calls get redirected into your C/C++ code inside the DLL which executes by remianing inside dll.
6. Your C/C++ code runs, does whatever it needs (call Python, process bytes, etc.) by being inside dll,
and returns results back to SystemVerilog.


## Python C API Memory Management
When you work with the Python C API, things like modules, functions, strings, and tuples are all Python objects managed by the Python interpreter.
These objects live on Python’s own heap memory, not in your C stack.
C code doesn’t copy them — instead, it uses a PyObject* pointer as a handle to reference and manipulate them.
If an operation fails, the pointer is NULL; if it succeeds, you manage its lifetime with reference counting (Py_DECREF/Py_INCREF).





















set PATH=C:\Users\muham\AppData\Local\Programs\Python\Python313;%PATH%
set PYTHONHOME=C:\Users\muham\AppData\Local\Programs\Python\Python313
set PYTHONPATH=C:\Users\muham\AppData\Local\Programs\Python\Python313\Lib
