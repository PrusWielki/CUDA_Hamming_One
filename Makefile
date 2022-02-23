all: sudokugpu sudokucpu

sudokucpu: main.cpp
	g++ -o hammingcpu main.cpp
sudokugpu: 
	nvcc  -std=c++11 -o hamminggpu bozedopomoz2_New.cu
