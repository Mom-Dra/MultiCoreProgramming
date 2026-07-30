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

__global__ void myKernel(int* in, int* out)
{
	int tID{ blockDim.x * blockIdx.x + threadIdx.x };
	int temp{ 0 };

	for (int i = 0; i < 250; ++i)
		temp = (temp + in[tID] * 5) % 10;

	out[tID] = temp;
}

int stream()
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Single Stream"));
	timer.setTimerName(1, const_cast<char*>("Host -> Device"));
	timer.setTimerName(2, const_cast<char*>("Kernel execution"));
	timer.setTimerName(3, const_cast<char*>("Device -> Host"));
	timer.setTimerName(4, const_cast<char*>("Multiple streams"));
	timer.setTimerName(5, const_cast<char*>("CUDA Device with Shared Memory"));

	//cudaEvent_t start, stop;
	//cudaEventCreate(&start);
	//cudaEventCreate(&stop);

	//cudaEventRecord(start);

	////myKernel << <1, 1024 >> > (arguments);

	//cudaEventRecord(stop);
	//cudaEventSynchronize(stop);

	//float time;
	//cudaEventElapsedTime(&time, start, stop);

	//cudaEventDestroy(start);
	//cudaEventDestroy(stop);

	//std::cout << "time: " << time << '\n';


	constexpr int NumBlock{ 128 * 1024 };
	constexpr int NumTInB{ 1024 };
	constexpr int ArraySize{ NumTInB * NumBlock };
	constexpr int NumStream{ 2 };

	int* in, * out, * out2;

	cudaMallocHost(&in, sizeof(int) * ArraySize);
	memset(in, 0, sizeof(int) * ArraySize);

	cudaMallocHost(&out, sizeof(int) * ArraySize);
	memset(out, 0, sizeof(int) * ArraySize);

	cudaMallocHost(&out2, sizeof(int) * ArraySize);
	memset(out2, 0, sizeof(int) * ArraySize);

	int* dIn, * dOut;
	cudaMalloc(&dIn, sizeof(int) * ArraySize);
	cudaMalloc(&dOut, sizeof(int) * ArraySize);

	for (int i{ 0 }; i < ArraySize; ++i)
	{
		in[i] = rand() % 10;
	}

	// Single stream version
	timer.onTimer(0);

	timer.onTimer(1);
	cudaMemcpy(dIn, in, sizeof(int) * ArraySize, cudaMemcpyHostToDevice);
	timer.offTimer(1);

	timer.onTimer(2);
	myKernel << <NumBlock, NumTInB >> > (dIn, dOut);
	cudaDeviceSynchronize();
	timer.offTimer(2);

	timer.onTimer(3);
	cudaMemcpy(out, dOut, sizeof(int) * ArraySize, cudaMemcpyDeviceToHost);
	timer.offTimer(3);

	timer.offTimer(0);

	// Multiple stream version
	cudaStream_t stream[NumStream];

	for (int i{ 0 }; i < NumStream; ++i)
		cudaStreamCreate(&stream[i]);

	timer.onTimer(4);

	int chunkSize{ ArraySize / NumStream };

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	float time;

	for (int i{ 0 }; i < NumStream; ++i)
	{
		int offset = chunkSize * i;
		cudaMemcpyAsync(dIn + offset, in + offset, sizeof(int) * chunkSize, cudaMemcpyHostToDevice, stream[i]);
		cudaEventRecord(start);
		myKernel << <NumBlock / NumStream, NumTInB, 0, stream[i] >> > (dIn + offset, dOut + offset);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&time, start, stop);
		cudaMemcpyAsync(out2 + offset, dOut + offset, sizeof(int) * chunkSize, cudaMemcpyDeviceToHost, stream[i]);
	}

	cudaDeviceSynchronize();
	timer.offTimer(4);

	for (int i{ 0 }; i < ArraySize; ++i)
	{
		if (out[i] != out2[i])
			std::cout << '!';
	}

	for (int i{ 0 }; i < NumStream; ++i)
		cudaStreamDestroy(stream[i]);

	timer.printTimer();

	cudaFree(dIn);
	cudaFree(dOut);

	cudaFreeHost(in);
	cudaFreeHost(out);
	cudaFreeHost(out2);

	return 0;
}