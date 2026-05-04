#include <iostream>
#include <thread>
#include <chrono>
#include <omp.h>

void barrier()
{
	int tID{ 0 };

#pragma omp parallel num_threads(8) private(tID)
	{
		tID = omp_get_thread_num();

		if (tID % 2 == 0)
			std::this_thread::sleep_for(std::chrono::microseconds(50));

		std::printf("[%d] before\n", tID);

#pragma omp barrier
		std::printf("[%d] after\n", tID);
	}

}