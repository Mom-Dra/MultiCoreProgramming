#include <iostream>

int scopeOfVar()
{
	constexpr int numOfThreads{ 4 };
	int priVal{ 100 };
	int a{ 77 };

#pragma omp parallel for num_threads(numOfThreads) shared(a), private(priVal)
	for (int i{ 0 }; i < numOfThreads; ++i)
	{
		priVal += i;
		a += priVal;

		std::printf("a: %d\n", a);
		std::printf("priVal: %d\n", priVal);
	}

	std::cout << priVal;

	return 0;
}