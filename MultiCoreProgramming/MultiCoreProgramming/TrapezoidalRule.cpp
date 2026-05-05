#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <array>
#include "DS_timer.h"
#include "DS_definitions.h"

void genRandomInput();

inline double fx(double x)
{
	return x * x;
}

inline double getArea(double a, double b, double h)
{
	return h * (fx(a) + fx(b)) * 0.5;
}

int TrapezoidalRule(int argc, char* argv[])
{
	constexpr int A{ -10 };
	constexpr int B{ 10 };
	constexpr int N{ 1000000000 };

	DS_timer timer{ 7 };
	timer.setTimerName(0, const_cast<char*>("Serial"));
	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
	timer.setTimerName(2, const_cast<char*>("Parallel 2"));
	timer.setTimerName(3, const_cast<char*>("Parallel 4"));
	timer.setTimerName(4, const_cast<char*>("Parallel 8"));
	timer.setTimerName(5, const_cast<char*>("Parallel 16"));
	timer.setTimerName(6, const_cast<char*>("Parallel 32"));

	genRandomInput();

	// Serial code
	timer.onTimer(0);

	double areaS{ 0.0 };
	double step{ static_cast<double>(B - A) / N };

	for (int i{ 0 }; i < N; ++i)
	{
		areaS += getArea(A + step * i, A + step * (i + 1), step);
	}

	timer.offTimer(0);

	std::cout << "Serial: " << areaS << '\n';


	// Parallel code
	timer.onTimer(1);
	constexpr int numOfThreads{ 8 };
	double areaP{ 0.0 };
#pragma omp parallel num_threads(numOfThreads) reduction(+:areaP)
	{
		int tID{ omp_get_thread_num() };

#pragma omp for
		for (int i{ 0 }; i < N; ++i)
		{
			areaP += getArea(A + step * i, A + step * (i + 1), step);
		}
	}

	timer.offTimer(1);

	std::cout << "Parallel: " << areaP << '\n';


	// Check reulsts
	if (std::abs(areaP - areaS) > std::numeric_limits<float>::epsilon())
	{
		std::cout << "Results are not matched\n";
	}


	timer.printTimer();
	EXIT_WIHT_KEYPRESS;
}

//void genRandomInput(void) {
//	// A matrix
//	LOOP_INDEX(row, m) {
//		LOOP_INDEX(col, n) {
//			A[row][col] = GenFloat;
//		}
//	}
//
//	LOOP_I(n)
//		X[i] = GenFloat;
//
//	memset(Y_serial, 0, sizeof(float)*m);
//	memset(Y_parallel, 0, sizeof(float)*m);
//}