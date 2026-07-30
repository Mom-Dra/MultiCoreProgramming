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

__global__ void matrixMultiplication(const float* A, const float* B, float* C, int m, int n, int k)
{
	int col{ blockDim.x * blockIdx.x + threadIdx.x };
	int row{ blockDim.y * blockIdx.y + threadIdx.y };
	int index{ row * n + col };

	if (row < m && col < n)
	{
		float val{ 0.0f };

		for (int i{ 0 }; i < k; ++i)
		{
			val += A[row * k + i] * B[n * i + col];
		}

		C[index] = val;
	}
}

__global__ void matrixMultiplicationWithSharedMemory(const float* A, const float* B, float* C, int m, int n, int k)
{
	constexpr int TileSize{ 16 };

	__shared__ float sA[TileSize][TileSize];
	__shared__ float sB[TileSize][TileSize];

	int col{ blockDim.x * blockIdx.x + threadIdx.x };
	int row{ blockDim.y * blockIdx.y + threadIdx.y };
	int index{ row * n + col };

	int w{ ceil(static_cast<float>(k) / TileSize) };

	float val{ 0.0f };
	for (int t{ 0 }; t < w; ++t)
	{
		if (row < m && (t * TileSize + threadIdx.x) < k)
			sA[threadIdx.y][threadIdx.x] = A[row * k + t * TileSize + threadIdx.x];
		else sA[threadIdx.y][threadIdx.x] = 0.0f;

		if (col < n && (t * TileSize + threadIdx.y) < k)
			sB[threadIdx.y][threadIdx.x] = B[(threadIdx.y + t * TileSize) * n + col];
		else sB[threadIdx.y][threadIdx.x] = 0.0f;

		__syncthreads();

		for (int i{ 0 }; i < TileSize; ++i)
		{
			val += sA[threadIdx.y][i] * sB[i][threadIdx.x];
		}

		__syncthreads();
	}

	if (row < m && col < n)
		C[index] = val;
}

std::vector<float> MulOpenMP(const std::vector<float>& A, const std::vector<float>& B, int m, int n, int k)
{
	std::vector<float> C(m * n, 0.0f);

#pragma omp parallel for
	for (int i{ 0 }; i < m; ++i)
	{
		for (int c{ 0 }; c < n; ++c)
		{
			float val{ 0.0f };

			for (int j{ 0 }; j < k; ++j)
			{
				val += A[i * k + j] * B[j * n + c];
			}

			C[i * n + c] = val;
		}
	}

	return C;
}

std::vector<float> MulSequential(const std::vector<float>& A, const std::vector<float>& B, int m, int n, int k) {
	std::vector<float> C(m * n, 0.0f);

	for (size_t i{ 0 }; i < m; ++i)
	{
		for (size_t c{ 0 }; c < n; ++c)
		{
			float val{ 0.0f };

			for (size_t j{ 0 }; j < k; ++j)
			{
				val += A[i * k + j] * B[j * n + c];
			}

			C[i * n + c] = val;
		}
	}

	return C;
}

bool checkMatrix(const std::vector<float>& C1, const std::vector<float>& C2)
{
	for (size_t i{ 0 }; i < C1.size(); ++i)
	{
		if (C1[i] != C2[i]) return false;
	}

	return true;
}

int MatirxMultiplication()
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel"));
	timer.setTimerName(2, const_cast<char*>("CUDA Host -> Device"));
	timer.setTimerName(3, const_cast<char*>("CUDA Device"));
	timer.setTimerName(4, const_cast<char*>("CUDA Device -> Host"));
	timer.setTimerName(5, const_cast<char*>("CUDA Device with Shared Memory"));

	constexpr int m{ 1024 };
	constexpr int n{ 2048 };
	constexpr int k{ 512 };

	std::vector<float> A(m * k, 1);
	std::vector<float> B(k * n, 2);
	std::vector<float> C(m * n, 0);

	timer.onTimer(0);
	std::vector<float> C1{ MulSequential(A, B, m, n, k) };
	timer.offTimer(0);

	timer.onTimer(1);
	std::vector<float> C2{ MulOpenMP(A, B, m, n, k) };
	timer.offTimer(1);

	bool check{ checkMatrix(C1, C2) };

	if (!check) std::cout << "is not same!\n";
	else std::cout << "same!\n";

	// 여기다 CUDA 프로그래밍 해보자
	// 스레드를 m x n개!

	dim3 block{ 16, 16 };
	dim3 grid{ static_cast<uint32_t> (ceil(static_cast<float>(n) / block.x)), static_cast<uint32_t>(ceil(static_cast<float>(m) / block.y)) };

	float* dA, * dB, * dC;

	timer.onTimer(2);
	cudaMalloc(&dA, m * k * sizeof(float));
	cudaMalloc(&dB, k * n * sizeof(float));
	cudaMalloc(&dC, m * n * sizeof(float));

	cudaMemcpy(dA, A.data(), m * k * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(dB, B.data(), k * n * sizeof(float), cudaMemcpyHostToDevice);
	cudaMemcpy(dC, C.data(), m * n * sizeof(float), cudaMemcpyHostToDevice);
	timer.offTimer(2);

	timer.onTimer(3);
	matrixMultiplication << <grid, block >> > (dA, dB, dC, m, n, k);
	cudaDeviceSynchronize();
	timer.offTimer(3);

	timer.onTimer(4);
	cudaMemcpy(C2.data(), dC, m * n * sizeof(float), cudaMemcpyDeviceToHost);
	timer.offTimer(4);

	check = checkMatrix(C1, C2);
	if (!check) std::cout << "is not same!\n";
	else std::cout << "same!\n";


	timer.onTimer(5);
	matrixMultiplication << <grid, block >> > (dA, dB, dC, m, n, k);
	cudaDeviceSynchronize();
	timer.offTimer(5);

	cudaMemcpy(C2.data(), dC, m * n * sizeof(float), cudaMemcpyDeviceToHost);
	cudaFree(dA);
	cudaFree(dB);
	cudaFree(dC);

	check = checkMatrix(C1, C2);
	if (!check) std::cout << "is not same!\n";
	else std::cout << "same!\n";

	timer.printTimer();

	return 0;
}