#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <array>
#include <random>
#include "DS_timer.h"
#include "DS_definitions.h"

int histogram(int argc, char* argv[])
{
	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
	timer.setTimerName(2, const_cast<char*>("Parallel 2"));
	timer.setTimerName(3, const_cast<char*>("Parallel 4"));
	timer.setTimerName(4, const_cast<char*>("Parallel 8"));
	timer.setTimerName(5, const_cast<char*>("Parallel 16"));
	timer.setTimerName(6, const_cast<char*>("Parallel 32"));

	// Serial code

	constexpr int Size{ 1000 };
	constexpr int NumOfElement{ Size * Size * Size };
	constexpr int NumOfBins{ 10 };
	constexpr int NumOfThreads{ 8 };

	std::random_device rd;
	std::default_random_engine gen{ rd() };
	std::uniform_real_distribution<float> dist(0.0f, NumOfBins - 1);

	//std::array<float, Size* Size* Size> arr;
	std::vector<float> arr(NumOfElement);
	std::generate(arr.begin(), arr.end(), [&]() { return dist(gen); });

	std::array<int, NumOfBins> bin1{};
	timer.onTimer(0);
	for (auto num : arr)
	{
		++bin1[static_cast<int>(num)];
	}
	timer.offTimer(0);

	// Parallel code
	std::array<int, NumOfBins> bin2{};
	std::array<std::array<int, NumOfBins>, NumOfThreads> localBins2{};

	timer.onTimer(1);
#pragma omp parallel num_threads(NumOfThreads)
	{
		int tID{ omp_get_thread_num() };

#pragma omp for
		for (int i{ 0 }; i < NumOfElement; ++i)
		{
			++localBins2[tID][static_cast<int>(arr[i])];
		}
	}

	for (const auto& arr : localBins2)
	{
		for (size_t i{ 0 }; i < arr.size(); ++i)
			bin2[i] += arr[i];
	}
	timer.offTimer(1);

	std::array<int, NumOfBins> bin3{};
	timer.onTimer(2);
#pragma omp parallel num_threads(NumOfThreads)
	{
		std::array<int, NumOfBins> localBin{};

#pragma omp for
		for (int i{ 0 }; i < NumOfElement; ++i)
			++localBin[static_cast<int>(arr[i])];

		for (int i{ 0 }; i < NumOfBins; ++i)
		{
#pragma omp atomic
			bin3[i] += localBin[i];
		}
	}
	timer.offTimer(2);

	std::array<int, NumOfBins> bin4{};
	std::array<std::array<int, NumOfBins>, NumOfThreads> localBins4{};

	timer.onTimer(3);
#pragma omp parallel num_threads(NumOfThreads)
	{
		int tID{ omp_get_thread_num() };

#pragma omp for
		for (int i{ 0 }; i < NumOfElement; ++i)
			++localBins4[tID][static_cast<int>(arr[i])];

		int offset{ 1 };
		while (offset < NumOfThreads)
		{
			if (tID % (offset * 2) == 0)
			{
				for (int i{ 0 }; i < NumOfBins; ++i)
					localBins4[tID][i] += localBins4[tID + offset][i];
			}

#pragma omp barrier
			offset *= 2;
		}
	}

	for (int i{ 0 }; i < NumOfBins; ++i)
		bin4[i] = localBins4[0][i];

	timer.offTimer(3);


	std::array<int, NumOfBins> bin5{};
	std::array<std::array<int, NumOfBins>, NumOfThreads> localBins5{};
	timer.onTimer(4);
#pragma omp parallel num_threads(NumOfThreads)
	{
		int tID{ omp_get_thread_num() };
		std::array<int, NumOfBins> localBin{};

#pragma omp for
		for (int i{ 0 }; i < NumOfElement; ++i)
			++localBin[static_cast<int>(arr[i])];

		for (int i{ 0 }; i < NumOfBins; ++i)
			localBins5[tID][i] = localBin[i];

#pragma omp barrier

		int offset{ 1 };
		while (offset < NumOfThreads)
		{
			if (tID % (offset * 2) == 0)
			{
				for (int i{ 0 }; i < NumOfBins; ++i)
					localBins4[tID][i] += localBins4[tID + offset][i];
			}

#pragma omp barrier
			offset *= 2;
		}
	}

	for (int i{ 0 }; i < NumOfBins; ++i)
		bin5[i] = localBins5[0][i];

	timer.offTimer(4);

	// Check reulsts

	for (int i{ 0 }; i < 10; ++i)
	{
		if (bin1[i] != bin2[i])
		{
			std::cout << "not match result!\n";
			break;
		}
	}


	timer.printTimer();
	EXIT_WIHT_KEYPRESS;
}
