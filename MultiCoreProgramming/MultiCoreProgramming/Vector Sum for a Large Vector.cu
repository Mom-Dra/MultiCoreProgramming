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

__global__ void matrixSum2D2D(const int* A, const int* B, int* C, size_t size)
{
	int col{ blockDim.x * blockIdx.x + threadIdx.x };
	int row{ blockDim.y * blockIdx.y + threadIdx.y };
	int index{ row * size + col };

	if (row < size && col < size)
	{
		C[index] = A[index] + B[index];
	}
}

__global__ void matrixSum1D1D(const int* A, const int* B, int* C, size_t totalSize)
{
	int index{ blockDim.x * blockIdx.x + threadIdx.x };

	if (index < totalSize)
	{
		C[index] = A[index] + B[index];
	}
}

__global__ void matrixSum2D1D(const int* A, const int* B, int* C, size_t size)
{
	int row{ blockIdx.y };
	int col{ blockDim.x * blockIdx.x + threadIdx.x };
	int index{ row * size + col };

	if (row < size && col < size)
	{
		C[index] = A[index] + B[index];
	}
}

//template <size_t Size>
//void matrixSum(const std::array<int, Size>& arr1, const std::array<int, Size>& arr2, std::array<int, Size>& arr3, size_t size)
//{
//	for (size_t i{ 0 }; i < size * size; ++i)
//	{
//		arr3[i] = arr1[i] + arr2[i];
//	}
//}

void matrixSumCPU(const std::vector<int>& A, const std::vector<int>& B, std::vector<int>& C, size_t size)
{
	for (size_t i{ 0 }; i < size * size; ++i)
	{
		C[i] = A[i] + B[i];
	}
}

bool verifyResult(const std::vector<int>& CPU, const std::vector<int>& GPU, size_t size)
{
	for (size_t i{ 0 }; i < size * size; ++i)
	{
		if (CPU[i] != GPU[i])
		{
			std::cout << "Mismatch at index " << i << '\n';
			return false;
		}
	}

	return true;
}

int vectorSumForALargeVector()
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
	timer.setTimerName(2, const_cast<char*>("Parallel 2"));

	constexpr size_t Size{ 8192 };
	constexpr size_t TotalSize{ Size * Size };
	constexpr size_t bytes{ TotalSize * sizeof(int) };

	std::vector<int> A(TotalSize, 1);
	std::vector<int> B(TotalSize, 2);
	std::vector<int> C_CPU(TotalSize, 0);
	std::vector<int> C_GPU(TotalSize, 0);

	matrixSumCPU(A, B, C_CPU, Size);

	int* dA, * dB, * dC;
	cudaMalloc(&dA, bytes);
	cudaMalloc(&dB, bytes);
	cudaMalloc(&dC, bytes);

	cudaMemcpy(dA, A.data(), bytes, cudaMemcpyHostToDevice);
	cudaMemcpy(dB, B.data(), bytes, cudaMemcpyHostToDevice);

	cudaEvent_t start, stop;
	cudaEventCreate(&start);
	cudaEventCreate(&stop);

	float ms{ 0.0f };

	std::cout << "\n========================================================\n";
	std::cout << std::left << std::setw(20) << "Layout" << std::setw(15) << "Block Size" << std::setw(15) << "Kernel Time" << "Check\n";
	std::cout << "--------------------------------------------------------\n";

	std::array<int, 5> blockSizes{ 64, 128, 256, 512, 1024 };
	for (int t : blockSizes)
	{
		int threadsPerBlock{ t };
		int blocksPerGrid{ static_cast<int> ((TotalSize + threadsPerBlock - 1) / threadsPerBlock) };

		cudaMemset(dC, 0, bytes);

		cudaEventRecord(start);
		matrixSum1D1D << <blocksPerGrid, threadsPerBlock >> > (dA, dB, dC, TotalSize);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&ms, start, stop);

		cudaMemcpy(C_GPU.data(), dC, bytes, cudaMemcpyDeviceToHost);
		bool passed{ verifyResult(C_CPU, C_GPU, Size) };

		std::cout << std::left << std::setw(20) << "1D Grid / 1D Block"
			<< std::setw(15) << t
			<< ms << " ms\t\t"
			<< (passed ? "PASS" : "FAIL") << "\n";
	}

	std::cout << "--------------------------------------------------------\n";

	std::array<dim3, 3> blockSizes2D{ dim3{8, 8}, dim3{16, 16}, dim3{32, 32} };
	for (const dim3& t : blockSizes2D)
	{
		dim3 threadsPerBlock{ t };
		dim3 blocksPerGrid{
			static_cast<uint32_t> ((Size + threadsPerBlock.x - 1) / threadsPerBlock.x),
			static_cast<uint32_t> ((Size + threadsPerBlock.y - 1) / threadsPerBlock.y)
		};

		cudaMemset(C_CPU.data(), 0, bytes);

		cudaEventRecord(start);
		matrixSum2D2D << <blocksPerGrid, threadsPerBlock >> > (dA, dB, dC, Size);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&ms, start, stop);

		cudaMemcpy(C_GPU.data(), dC, bytes, cudaMemcpyDeviceToHost);
		bool passed{ verifyResult(C_CPU, C_GPU, Size) };

		std::string dimStr = std::to_string(t.x) + "x" + std::to_string(t.y);
		std::cout << std::left << std::setw(20) << "2D Grid / 2D Block"
			<< std::setw(15) << dimStr
			<< ms << " ms\t\t"
			<< (passed ? "PASS" : "FAIL") << "\n";
	}

	std::cout << "--------------------------------------------------------\n";

	for (int t : blockSizes)
	{
		dim3 threadsPerBlock{ static_cast<uint32_t>(t), 1 };
		dim3 blocksPerGrid{
			static_cast<uint32_t>((Size + t - 1) / t),
			static_cast<uint32_t>(Size)
		};

		cudaMemset(dC, 0, bytes);

		cudaEventRecord(start);
		matrixSum2D1D << <blocksPerGrid, threadsPerBlock >> > (dA, dB, dC, Size);
		cudaEventRecord(stop);
		cudaEventSynchronize(stop);
		cudaEventElapsedTime(&ms, start, stop);

		cudaMemcpy(C_GPU.data(), dC, bytes, cudaMemcpyDeviceToHost);
		bool passed{ verifyResult(C_CPU, C_GPU, Size) };

		std::string dimStr = std::to_string(t) + "x1";
		std::cout << std::left << std::setw(20) << "2D Grid / 1D Block"
			<< std::setw(15) << dimStr
			<< ms << " ms\t\t"
			<< (passed ? "PASS" : "FAIL") << "\n";
	}

	std::cout << "========================================================\n";

	cudaFree(dA);
	cudaFree(dB);
	cudaFree(dC);
	cudaEventDestroy(start);
	cudaEventDestroy(stop);

	return 0;
}