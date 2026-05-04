#include <iostream>
#include <thread>
#include <omp.h>

int ProducerConsumer()
{

	int buf{ 0 };
	omp_lock_t lock;
	omp_init_lock(&lock);
	bool isFinish{ false };

#pragma omp parallel sections shared(isFinish, lock) num_threads(2)
	{
#pragma omp section // Producer
		{
			int numProduce{ 10 };
			while (numProduce > 0)
			{
				omp_set_lock(&lock);

				if (buf == 0)
				{
					buf = numProduce;
					std::printf("Produce push %d\n", buf);
					--numProduce;
				}

				omp_unset_lock(&lock);
				std::this_thread::sleep_for(std::chrono::microseconds(500));
			}

			isFinish = true;
		}

#pragma omp section // Consumer
		{
			int get{ 0 };
			while (!isFinish)
			{
				omp_set_lock(&lock);

				if (buf > 0)
				{
					get = buf;
					buf = 0;
					std::printf("Consumer get %d\n", get);
				}

				omp_unset_lock(&lock);
				std::this_thread::sleep_for(std::chrono::microseconds(500));
			}
		}
	}

	omp_destroy_lock(&lock);
	std::printf("Finished\n");

	return 0;
}