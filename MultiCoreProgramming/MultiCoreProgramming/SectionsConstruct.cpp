#include <iostream>
#include <omp.h>

void sectionConstruct()
{
	#pragma omp parallel num_threads(16)
	{
		#pragma omp sections
		{
			#pragma omp section
			std::printf("Section A, Thread: %d\n", omp_get_thread_num());

			#pragma omp section
			std::printf("Section B, Thread: %d\n", omp_get_thread_num());
		}
	}
}
