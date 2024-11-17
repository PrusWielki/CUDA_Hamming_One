all: hamminggpu hammingcpu

hammingcpu: cpu_hamming_distance.cpp
	g++ -o cpu_hamming_distance cpu_hamming_distance.cpp
hamminggpu: 
	nvcc  -std=c++11 -o gpu_hamming_distance gpu_hamming_distance.cu
