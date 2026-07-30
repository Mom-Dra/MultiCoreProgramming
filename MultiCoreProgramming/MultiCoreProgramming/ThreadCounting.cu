#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "DS_timer.h"
#include "DS_definitions.h"

#include <iostream>
#include <iomanip>
#include <array>
#include <vector>
#include <algorithm>
#include <random>
#include <chrono>
#include <omp.h>

__global__ void threadCounting_noSync(int* a)
{
	(*a)++;
}

__global__ void threadCounting_atomicGlobal(int* a)
{
	atomicAdd(a, 1);
}

__global__ void threadCounting_atomicShared(int* a)
{
	__shared__ int sa;

	if (threadIdx.x == 0)
		sa = 0;
	__syncthreads();

	atomicAdd(&sa, 1);
	__syncthreads();

	if (threadIdx.x == 0)
		atomicAdd(a, sa);
}

int threadCounting()
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel"));
	timer.setTimerName(2, const_cast<char*>("CUDA Host -> Device"));
	timer.setTimerName(3, const_cast<char*>("CUDA Device"));
	timer.setTimerName(4, const_cast<char*>("CUDA Device -> Host"));
	timer.setTimerName(5, const_cast<char*>("CUDA Device with Shared Memory"));

	int a{ 0 };
	int* d;

	cudaMalloc((void**)&d, sizeof(int));
	cudaMemset(d, 0, sizeof(int) * 1);

	timer.onTimer(0);
	threadCounting_noSync << <10240, 512 >> > (d);
	cudaDeviceSynchronize();
	timer.offTimer(0);

	cudaMemcpy(&a, d, sizeof(int), cudaMemcpyDeviceToHost);

	std::printf("%d\n", a);
	cudaFree(d);

	timer.printTimer();

	return 0;
}