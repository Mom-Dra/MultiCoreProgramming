
#include "cuda_runtime.h"
#include "device_launch_parameters.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "DS_timer.h"

cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size);

__global__ void addKernel(int *c, const int *a, const int *b)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    c[i] = a[i] + b[i];
}

__global__ void checkIndex(int& count)
{
    printf("threadIdx:(%d, %d, %d) blockIdx:(%d, %d, %d) blockDim:(%d, %d, %d) gridDim:(%d, %d, %d)\n"
        , threadIdx.x, threadIdx.y, threadIdx.z
        , blockIdx.x, blockIdx.y, blockIdx.z
        , blockDim.x, blockDim.y, blockDim.z
        , gridDim.x, gridDim.y, gridDim.z);

    ++count;
}

int main()
{
    //int nElem{ 6 };

    //dim3 block{ 3 };
    //dim3 grid{ (nElem + block.x - 1) / block.x };

    //printf("grid.x %d grid.y %d grid.z %d\n", grid.x, grid.y, grid.z);
    //printf("block.x %d block.y %d block.z %d\n", block.x, block.y, block.z);

    //checkIndex << <grid, block >> > ();
    //cudaDeviceReset();
    //return 0;


    DS_timer timer{ 5 };
    timer.setTimerName(0, "Total");
    timer.setTimerName(1, "Computation(Kernel)");
    timer.setTimerName(2, "Data Trans. : Host -> Device");
    timer.setTimerName(3, "Data Trans. : Device -> Host");
    timer.setTimerName(4, "VectorSum on Host");
    timer.initTimers();

    constexpr int NumData{ 1025 };
    constexpr int MemSize{ sizeof(int) * NumData };


    // 내 방식
    // block의 thread를 1024개 고정하고 가자!
    // 어떻게 디자인하냐..?
    // 홀수개면 딱 나우어 떨어지지도 않음!
    // block.x을 고정하고가?
    dim3 grid{ NumData / 256, 1, 1 };
    dim3 block{ 256, 1, 1 };

    int count{ 0 };

    checkIndex << < grid, block >> > (count);
    cudaDeviceSynchronize();
    //printf("count: %d\n", count);


    
    

    //int* a, * b, * c;
    //int* d_a, * d_b, * d_c;

    //int memSize{ sizeof(int) * NumData };
    //printf("%d elements, memSize = %d bytes\n", NumData, MemSize);

    //a = new int[NumData];
    //b = new int[NumData];
    //c = new int[NumData];

    //for (int i{ 0 }; i < NumData; ++i)
    //{
    //    a[i] = rand() % 10;
    //    b[i] = rand() % 10;
    //}

    //timer.onTimer(4);
    //for (int i{ 0 }; i < NumData; ++i)
    //    c[i] = a[i] + b[i];
    //timer.offTimer(4);

    //cudaMalloc(&d_a, memSize);
    //cudaMalloc(&d_b, memSize);
    //cudaMalloc(&d_c, memSize);

    //timer.onTimer(0);

    //timer.onTimer(2);
    //cudaMemcpy(d_a, a, memSize, cudaMemcpyHostToDevice);
    //cudaMemcpy(d_b, b, memSize, cudaMemcpyHostToDevice);
    //timer.offTimer(2);

    //// Kernel call
    //timer.onTimer(1);
    //addKernel << <grid, block >> > (d_c, d_a, d_b);
    //cudaDeviceSynchronize();
    //timer.offTimer(1);

    //timer.onTimer(3);
    //cudaMemcpy(c, d_c, memSize, cudaMemcpyDeviceToHost);
    //timer.offTimer(3);

    //timer.offTimer(0);
    //timer.printTimer();

    //// check results
    //bool result{ true };
    //for (int i{ 0 }; i < NumData; ++i)
    //{
    //    if ((a[i] + b[i]) != c[i])
    //    {
    //        printf("[%d] The results is not matched! (%d, %d)\n", i, a[i] + b[i], c[i]);
    //        result = false;
    //    }
    //}

    //if (result)
    //    printf("GPU works well!\n");

    //cudaFree(d_a);
    //cudaFree(d_b);
    //cudaFree(d_c);

    //delete[] a;
    //delete[] b;
    //delete[] c;

    //return 0;


    //const int arraySize = 5;
    //const int a[arraySize] = { 1, 2, 3, 4, 5 };
    //const int b[arraySize] = { 10, 20, 30, 40, 50 };
    //int c[arraySize] = { 0 };

    //// Add vectors in parallel.
    //cudaError_t cudaStatus = addWithCuda(c, a, b, arraySize);
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "addWithCuda failed!");
    //    return 1;
    //}

    //printf("{1,2,3,4,5} + {10,20,30,40,50} = {%d,%d,%d,%d,%d}\n",
    //    c[0], c[1], c[2], c[3], c[4]);

    //// cudaDeviceReset must be called before exiting in order for profiling and
    //// tracing tools such as Nsight and Visual Profiler to show complete traces.
    //cudaStatus = cudaDeviceReset();
    //if (cudaStatus != cudaSuccess) {
    //    fprintf(stderr, "cudaDeviceReset failed!");
    //    return 1;
    //}

    //return 0;
}

// Helper function for using CUDA to add vectors in parallel.
cudaError_t addWithCuda(int *c, const int *a, const int *b, unsigned int size)
{
    int *dev_a = 0;
    int *dev_b = 0;
    int *dev_c = 0;
    cudaError_t cudaStatus;

    // Choose which GPU to run on, change this on a multi-GPU system.
    cudaStatus = cudaSetDevice(0);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaSetDevice failed!  Do you have a CUDA-capable GPU installed?");
        goto Error;
    }

    // Allocate GPU buffers for three vectors (two input, one output)    .
    cudaStatus = cudaMalloc((void**)&dev_c, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_a, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    cudaStatus = cudaMalloc((void**)&dev_b, size * sizeof(int));
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMalloc failed!");
        goto Error;
    }

    // Copy input vectors from host memory to GPU buffers.
    cudaStatus = cudaMemcpy(dev_a, a, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    cudaStatus = cudaMemcpy(dev_b, b, size * sizeof(int), cudaMemcpyHostToDevice);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

    // Launch a kernel on the GPU with one thread for each element.
    //addKernel<<<1, size>>>(dev_c, dev_a, dev_b);

    // Check for any errors launching the kernel
    cudaStatus = cudaGetLastError();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "addKernel launch failed: %s\n", cudaGetErrorString(cudaStatus));
        goto Error;
    }
    
    // cudaDeviceSynchronize waits for the kernel to finish, and returns
    // any errors encountered during the launch.
    cudaStatus = cudaDeviceSynchronize();
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaDeviceSynchronize returned error code %d after launching addKernel!\n", cudaStatus);
        goto Error;
    }

    // Copy output vector from GPU buffer to host memory.
    cudaStatus = cudaMemcpy(c, dev_c, size * sizeof(int), cudaMemcpyDeviceToHost);
    if (cudaStatus != cudaSuccess) {
        fprintf(stderr, "cudaMemcpy failed!");
        goto Error;
    }

Error:
    cudaFree(dev_c);
    cudaFree(dev_a);
    cudaFree(dev_b);
    
    return cudaStatus;
}
