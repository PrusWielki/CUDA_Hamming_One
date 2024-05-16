all: sudokugpu sudokucpu

sudokucpu: cpu.cpp
	g++ -o hammingcpu cpu.cpp
sudokugpu: 
	nvcc  -std=c++11 -o hamminggpu gpu.cu
