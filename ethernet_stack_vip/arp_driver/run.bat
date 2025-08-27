
cls
del packet_generation.exe

cl dpi_c_wrapper.cpp /Fe:my_dpi.dll /LD /W0 ^
 /I "C:\Users\muham\AppData\Local\Programs\Python\Python313\include" ^
 /I "C:\questasim64_2024.1\include" ^
 /link /LIBPATH:"C:\Users\muham\AppData\Local\Programs\Python\Python313\libs" ^
 python313.lib "C:\questasim64_2024.1\win64\mtipli.lib"
vsim -c -do run.do