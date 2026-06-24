#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include "DS_timer.h"
#include "DS_definitions.h"

#include <iostream>
#include <array>
#include <vector>
#include <algorithm>
#include <random>
#include <chrono>

__global__ void vectorSum(const int* A, const int* B, int* C, size_t size)
{
	int i = blockIdx.x * blockDim.x + threadIdx.x;

	if (i < size)
	{
		C[i] = A[i] + B[i];
	}
}

void vectorAddCPU(const std::vector<int>& A, const std::vector<int>& B, std::vector<int>& C, size_t N)
{
	for (size_t i{ 0 }; i < N; ++i)
	{
		C[i] = A[i] + B[i];
	}
}

int VectorSumForALargeVector()
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
	timer.setTimerName(2, const_cast<char*>("Parallel 2"));

	constexpr size_t MinSize{ 1024 * 1024 };
	constexpr size_t MaxSize{ 1024 * 1024 * 128 };

	for (int N{ MinSize }; N <= MaxSize; N *= 2)
	{
		size_t bytes{ N * sizeof(int) };

		std::vector<int> A(N, 1);
		std::vector<int> B(N, 2);
		std::vector<int> C_CPU(N, 0);
		std::vector<int> C_GPU(N, 0);

		int* dA, * dB, * dC;
		cudaMalloc(&dA, bytes);
		cudaMalloc(&dB, bytes);
		cudaMalloc(&dC, bytes);

		cudaEvent_t start, stop;
		cudaEventCreate(&start);
		cudaEventCreate(&stop);
		float hToDTime{ 0.0f }, kernelTime{ 0.0f }, dToHTime{ 0.0f };

		cudaEventRecord(start);
		cudaMemcpy(dA, A.data(), bytes, cudaMemcpyHostToDevice);
		cudaMemcpy(dB, B.data(), bytes, cudaMemcpyHostToDevice);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&hToDTime, start, stop);

		constexpr int threadPerBlock{ 1024 };
		int blockPerGrid{ (N + threadPerBlock - 1) / threadPerBlock };

		cudaEventRecord(start);
		vectorSum <<<blockPerGrid, threadPerBlock >>> (dA, dB, dC, N);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&kernelTime, start, stop);

		cudaEventRecord(start);
		cudaMemcpy(C_GPU.data(), dC, bytes, cudaMemcpyDeviceToHost);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&dToHTime, start, stop);

		auto cpuStart{ std::chrono::high_resolution_clock::now() };
		vectorAddCPU(A, B, C_CPU, N);
		auto cpuStop{ std::chrono::high_resolution_clock::now() };
		std::chrono::duration<float, std::milli> cpuDuration{ cpuStop - cpuStart };

		bool isCorrect{ true };
		for (size_t i{ 0 }; i < N; ++i)
		{
			if (C_CPU[i] != C_GPU[i]) {
				isCorrect = false;
				break;
			}
		}

		std::cout << "Data Size (N)   : " << N << std::endl
			<< "CPU Time (ms)   : " << cpuDuration.count() << std::endl
			<< "H2D Time (ms)   : " << hToDTime << std::endl
			<< "Kernel Time(ms) : " << kernelTime << std::endl
			<< "D2H Time (ms)   : " << dToHTime << std::endl
			<< "Total GPU (ms)  : " << (hToDTime + kernelTime + dToHTime) << " (H2D + Kernel + D2H)" << std::endl
			<< "Result Check    : " << (isCorrect ? "PASS" : "FAIL") << std::endl
			<< "--------------------------------------------------" << std::endl;

		cudaFree(dA);
		cudaFree(dB);
		cudaFree(dC);
		cudaEventDestroy(start);
		cudaEventDestroy(stop);
	}

	return 0;
}