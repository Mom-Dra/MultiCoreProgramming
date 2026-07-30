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

//__global__ void myKernel(int* in, int* out)
//{
//	int tID{ blockDim.x * blockIdx.x + threadIdx.x };
//	int temp{ 0 };
//
//	for (int i = 0; i < 250; ++i)
//		temp = (temp + in[tID] * 5) % 10;
//
//	out[tID] = temp;
//}

void genRandomInput();

inline double fx(double x)
{
	return x * x;
}

//inline double fxDevice(double x)
//{
//	return x * x;
//}

inline double getArea(double a, double b, double h)
{
	return h * (fx(a) + fx(b)) * 0.5;
}

//__global__ inline double getAreaDevice(double a, double b, double h)
//{
//	return h * (fxDevice(a) + fxDevice(b)) * 0.5;
//}


// sharedMemory localSum 버전
//__global__ void getAreaKernel(int a, int b, double h, int size, double* area)
//{
//	int tID{ blockDim.x * blockIdx.x + threadIdx.x };
//
//	__shared__ double sArea;
//	if (threadIdx.x == 0) sArea = 0.0;
//	__syncthreads();
//
//	if (tID < size)
//	{
//		double myArea{ h * ((a + h * tID) * (a + h * tID) + (a + h * tID + h) * (a + h * tID + h)) * 0.5 };
//
//		atomicAdd(&sArea, myArea);
//		__syncthreads();
//
//		if (threadIdx.x == 0)
//			atomicAdd(area, sArea);
//	}
//}

// reduction 버전
//__global__ void getAreaKernel(int a, int b, double h, int size, double* area)
//{
//	int tID{ blockDim.x * blockIdx.x + threadIdx.x };
//
//	__shared__ double sArea[256];
//	sArea[threadIdx.x] = 0.0;
//	__syncthreads();
//
//	double myArea{ 0.0 };
//
//	if (tID < size)
//	{
//		myArea = { h * ((a + h * tID) * (a + h * tID) + (a + h * tID + h) * (a + h * tID + h)) * 0.5 };
//	}
//
//	sArea[threadIdx.x] = myArea;
//	__syncthreads();
//
//	int offset{ 1 };
//
//	while (offset < 256)
//	{
//		if (threadIdx.x % (offset * 2) == 0)
//			sArea[threadIdx.x] += sArea[threadIdx.x + offset];
//
//		__syncthreads();
//		offset *= 2;
//	}
//
//	if (threadIdx.x == 0)
//		atomicAdd(area, sArea[0]);
//}

// Avoid Bank Conflict
//__global__ void getAreaKernel(int a, int b, double h, int size, double* area)
//{
//	int tID{ blockDim.x * blockIdx.x + threadIdx.x };
//
//	__shared__ double sArea[256];
//	sArea[threadIdx.x] = 0.0;
//	__syncthreads();
//
//	double myArea{ 0.0 };
//
//	if (tID < size)
//	{
//		myArea = { h * ((a + h * tID) * (a + h * tID) + (a + h * tID + h) * (a + h * tID + h)) * 0.5 };
//	}
//
//	sArea[threadIdx.x] = myArea;
//	__syncthreads();
//
//	int offset{ 256 / 2 };
//
//	while (offset > 0)
//	{
//		if (threadIdx.x < offset)
//			sArea[threadIdx.x] += sArea[threadIdx.x + offset];
//
//		__syncthreads();
//		offset /= 2;
//	}
//
//	if (threadIdx.x == 0)
//		atomicAdd(area, sArea[0]);
//}

__global__ void getAreaKernel(int a, int b, double h, int size, double* area)
{
	int tID{ blockDim.x * blockIdx.x + threadIdx.x };

	__shared__ double sArea[256];
	sArea[threadIdx.x] = 0.0;
	__syncthreads();

	double myArea{ 0.0 };

	if (tID < size)
	{
		myArea = { h * ((a + h * tID) * (a + h * tID) + (a + h * tID + h) * (a + h * tID + h)) * 0.5 };
	}

	sArea[threadIdx.x] = myArea;
	__syncthreads();

	int offset{ 256 / 2 };

	while (offset > 0)
	{
		if (threadIdx.x < offset)
			sArea[threadIdx.x] += sArea[threadIdx.x + offset];

		__syncthreads();
		offset /= 2;
	}

	if (threadIdx.x == 0)
		atomicAdd(area, sArea[0]);
}

int TrapezoidalRule()
{
	constexpr int A{ -10 };
	constexpr int B{ 10 };
	constexpr int N{ 1024 * 1024 * 1024 };

	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
	timer.setTimerName(2, const_cast<char*>("CUDA"));
	timer.setTimerName(3, const_cast<char*>("Parallel 4"));
	timer.setTimerName(4, const_cast<char*>("Parallel 8"));
	timer.setTimerName(5, const_cast<char*>("Parallel 16"));
	timer.setTimerName(6, const_cast<char*>("Parallel 32"));

	genRandomInput();

	// Serial code
	timer.onTimer(0);

	double areaS{ 0.0 };
	double step{ static_cast<double>(B - A) / N };

	for (int i{ 0 }; i < N; ++i)
	{
		areaS += getArea(A + step * i, A + step * (i + 1), step);
	}

	timer.offTimer(0);

	std::cout << "Serial: " << areaS << '\n';


	// Parallel code
	timer.onTimer(1);
	constexpr int numOfThreads{ 8 };
	double areaP{ 0.0 };
#pragma omp parallel num_threads(numOfThreads) reduction(+:areaP)
	{
		int tID{ omp_get_thread_num() };

#pragma omp for
		for (int i{ 0 }; i < N; ++i)
		{
			areaP += getArea(A + step * i, A + step * (i + 1), step);
		}
	}

	timer.offTimer(1);

	std::cout << "Parallel: " << areaP << '\n';

	// CUDA
	constexpr int CUDA_N{ 1024 * 1024 * 1024 };
	int blockSize{ 256 };
	int gridSize{ static_cast<int>(ceilf(static_cast<float>(CUDA_N) / blockSize)) };

	//int* a, * b;
	double* area;
	double Area;
	double hH{ static_cast<double>(B - A) / CUDA_N };

	cudaMalloc(&area, sizeof(double));

	timer.onTimer(2);
	getAreaKernel << <gridSize, blockSize >> > (A, B, hH, CUDA_N, area);
	cudaDeviceSynchronize();
	timer.offTimer(2);

	cudaMemcpy(&Area, area, sizeof(double), cudaMemcpyDeviceToHost);

	std::cout << "CUDA: " << Area << '\n';

	// Check reulsts
	double tolerance = 1e-8;
	if (std::abs(Area - areaS) > std::numeric_limits<double>::epsilon())
	{
		std::cout << "Results are not matched\n";
	}

	timer.printTimer();
	EXIT_WIHT_KEYPRESS;
}

int main() {
	TrapezoidalRule();
}
