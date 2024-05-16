#define n 100000
#define l 1000

#include <chrono>

#include <cuda.h>

#include <stdlib.h>

#include <stdio.h>

#include <cmath>

#include <cstdio>

#include <cuda_runtime.h>

#include <cstdlib>

#include <vector>

#include <fstream>

#include <cstring>

#include <algorithm>

//#include <curand.h>

#include <bitset>

#include <cassert>

//kernel accepts a n*l 1d array of bools (bitsetarray), a n*l 1d array of ints(bitsetpairs), where index of pairs are stored,
//a n sized 1d array indexes that keeps track of unused spaces in bitsetpairs and an int pairs that counts the numer of pairs

__global__ void kernel(bool * bitsetarray, int * bitsetpairs, int*indexes, int* pairs) {

  int index = blockIdx.x * blockDim.x + threadIdx.x; // index of a word currently being compared to others
  int number_of_different_bits=0;
  //int bitsetpairs_index=0;
  
  while (index < n) { //repeat the process until we run out of pairs of strings
    for(int j=0;j<n;j++){ //iterate over all n words from bitsetarray
		for(int i=0;i<l;i++){ //iterate over all bits from a given j word
    //TODO: insted of i=0, try i=j, and then dont divide the pairs by 2
		if(bitsetarray[index*l+i]!=bitsetarray[j*l+i]){
		number_of_different_bits++;}
		if(number_of_different_bits>1){ //if number of different bits exceeds 1 we can skip to the next word to save time
		break;}}
		
	
	if(number_of_different_bits==1) //hamming distance equals 1
	{
		(*pairs)++;
	bitsetpairs[index*l+indexes[index]]=j; // save index of word <j> at row <index> in a free column
	indexes[index]++; //move to the next free place
	}	
	number_of_different_bits=0;
        }

    
  

    index += blockDim.x * gridDim.x; //move to the next word to be compared to others
  }

}

void load_from_file(char * file_name, bool * bitsetarray) {
  FILE * a_file = fopen(file_name, "r");

  if (a_file == NULL) {
    printf("unable to load file\n");
    return;
  }

  char temp;

  for (int i = 0; i < n; i++) {
      for(int j=0;j<l;j++){
      if (!fscanf(a_file, "%c\n", & temp)) {
        printf("File loading error!\n");
        return;
      }

      if (temp == '1') {
        bitsetarray[i*l+j]=true;
      } 
      else
      bitsetarray[i*l+j]=false;
      }
  }
}
void print_word(bool*bitsetarray, int index){
	for(int i=0;i<l;i++){
		printf("%d",bitsetarray[index*l+i]);	
	}
	printf("\n");
	
}
void print_solution(bool* bitsetarray,int*bitsetpairs, int* indexes, int *pairs){
printf("Number of  pairs found = %d\n", (*pairs)/2); //we divide by two, cause every pair as of now is counted twice
for(int i=0;i<n;i++){
  printf("Words with Hamming distance equal to 1 with word: ");
  print_word(bitsetarray,i);
  printf("are:\n");
  for(int j=0;j<indexes[i];j++){
      print_word(bitsetarray,bitsetpairs[i*l+j]);

  }
}

}
//just prints the contents of bitsetpairs
void test_bitsetpairs(int *bitsetpairs){
	
	for(int i=0;i<n;i++)
	{
		for(int j=0;j<l;j++){
			printf("%d",bitsetpairs[i*l+j]);
		}
		printf("\n");
	}
	
	
}

int main(int argc, char ** argv) {

  if (argc < 4) {
    printf("threads_per_block max_blocks file_with_data\n");
    return 1;
  }

  //the below are of no use currently
  int dev = 0;
  cudaDeviceProp deviceProp;
  cudaGetDeviceProperties( & deviceProp, dev);

  unsigned int maxThreads = deviceProp.maxThreadsPerBlock;

  //event creation
  cudaEvent_t start, stop;
  cudaEventCreate( & start);
  cudaEventCreate( & stop);
  cudaEvent_t startbfs, stopbfs;
  cudaEventCreate( & startbfs);
  cudaEventCreate( & stopbfs);

  cudaEvent_t start_memalloc, stop_memalloc;
  cudaEventCreate( & start_memalloc);
  cudaEventCreate( & stop_memalloc);

  cudaEvent_t start_reading, stop_reading;
  cudaEventCreate( & start_reading);
  cudaEventCreate( & stop_reading);

  cudaEvent_t start_copying, stop_copying;
  cudaEventCreate( & start_copying);
  cudaEventCreate( & stop_copying);

  auto begin = std::chrono::high_resolution_clock::now();

  //read arguments
  const unsigned int threadsPerBlock = atoi(argv[1]);
  const unsigned int maxBlocks = atoi(argv[2]);
  char * file_name = argv[3];

  //auto bitsetarray = new bitset<l>[n];
  bool *bitsetarray = new bool[n*l];
  //std::bitset<l> bitsetarray[n]; 

  //read data
  cudaEventRecord(start_reading);
  load_from_file(file_name, bitsetarray);
  cudaEventRecord(stop_reading);


  //initialization of variables
  //auto bitsetpairs = new bitset<l>[n];
  int * bitsetpairs=new int[n*l];
  int * indexes=new int[n];
  int *pairs=new int;
  (*pairs)=0;
  memset(bitsetpairs,0,n*l*sizeof(int));
  memset(indexes,0,n*sizeof(int));
  int * indexes_dev=new int[n];
  int * bitsetpairs_dev=new int[n*l];
  int *pairs_dev=new int;
  bool * bitsetarray_dev=new bool[n*l];
  //std::vector <int> *bitsetpairs=new std::vector<int>[n];
  //std::vector<int> *bitsetpairs_dev;// = new vector<int>[n];
  //std::bitset<l> *bitsetarray_dev;// =new bitset<l>[n];

  cudaEventRecord(start_memalloc);
  cudaMalloc( & pairs_dev,  sizeof(int));
  cudaMalloc( & indexes_dev, n * sizeof(int));
  cudaMalloc( & bitsetpairs_dev, n *l* sizeof(int));
  cudaMalloc( & bitsetarray_dev, n *l* sizeof(bool));
  cudaEventRecord(stop_memalloc);


  cudaEventRecord(start_copying);
  cudaMemcpy(pairs_dev, pairs, sizeof(int), cudaMemcpyHostToDevice);
  cudaMemcpy(bitsetarray_dev, bitsetarray, n *l* sizeof(bool), cudaMemcpyHostToDevice);
  cudaMemcpy(indexes_dev, indexes, n * sizeof(int), cudaMemcpyHostToDevice);
  cudaEventRecord(stop_copying);
  
  cudaEventRecord(start);
  kernel <<< maxBlocks, threadsPerBlock >>> (bitsetarray_dev,bitsetpairs_dev,indexes_dev,pairs_dev);
    cudaEventRecord(stop);

  cudaMemcpy(bitsetpairs, bitsetpairs_dev, n *l* sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(indexes, indexes_dev, n * sizeof(int), cudaMemcpyDeviceToHost);
  cudaMemcpy(pairs, pairs_dev, sizeof(int), cudaMemcpyDeviceToHost);
  
  //test_bitsetpairs(bitsetpairs);
  

  //pairs are actually counted based on values in "indexes" since it keeps track of number of pairs for each word
  //so the pair counting in kernel can be removed, Im just scared to modify anything without testing it
  (*pairs)=0;
  for(int i=0;i<n;i++)
  (*pairs)+=indexes[i];
  


  //the function print_solution also prints pairs for each word, in the case when n and l are big its output is rather unreadable
  //print_solution(bitsetarray,bitsetpairs,indexes,pairs);
	printf("Number of pairs found: %d\n",(*pairs)/2);


  delete[] bitsetarray;
  delete[] bitsetpairs;
  cudaFree(bitsetarray_dev);
  cudaFree(bitsetpairs_dev);
  //untested changes:
  delete[] indexes;
  delete pairs;
  cudaFree(indexes_dev);
  cudaFree(pairs_dev);
  //

  cudaEventSynchronize(stop);


  //print results of time measurments
  float millisecondscopying = 0;
  cudaEventElapsedTime( & millisecondscopying, start_copying, stop_copying);
  printf("Data Copying: %.3f seconds.\n", 0.001 * millisecondscopying);
  float millisecondsreading = 0;
  cudaEventElapsedTime( & millisecondsreading, start_reading, stop_reading);
  printf("Data Loading: %.3f seconds.\n", 0.001 * millisecondsreading);
  float milliseconds = 0;
  cudaEventElapsedTime( & milliseconds, start, stop);
  printf("Kernel: %.3f seconds.\n", 0.001 * milliseconds);
  float millisecondsmem = 0;
  cudaEventElapsedTime( & millisecondsmem, start_memalloc, stop_memalloc);
  printf("MemAlloc: %.3f seconds.\n", 0.001 * millisecondsmem);
  auto end = std::chrono::high_resolution_clock::now();
  auto elapsed = std::chrono::duration_cast < std::chrono::nanoseconds > (end - begin);

  printf("Time measured(total time): %.3f seconds.\n", elapsed.count() * 1e-9);
  return 0;

}
