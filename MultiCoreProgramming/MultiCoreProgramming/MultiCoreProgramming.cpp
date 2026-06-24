#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include <array>
#include <random>
#include <thread>
#include "DS_timer.h"
#include "DS_definitions.h"
//
//int main(int argc, char* argv[])
//{
//	DS_timer timer{ 7 };
//	timer.setTimerName(0, const_cast<char*>("Serial"));
//	timer.setTimerName(1, const_cast<char*>("Parallel 1"));
//	timer.setTimerName(2, const_cast<char*>("Parallel 2"));
//	timer.setTimerName(3, const_cast<char*>("Parallel 4"));
//	timer.setTimerName(4, const_cast<char*>("Parallel 8"));
//	timer.setTimerName(5, const_cast<char*>("Parallel 16"));
//	timer.setTimerName(6, const_cast<char*>("Parallel 32"));
//
//	// Serial code
//	constexpr size_t NumSize{ 1000000 };
//	
//	std::random_device rd;
//	std::default_random_engine gen{ rd() };
//	std::uniform_int_distribution<int> dis{ 1, 100 };
//
//	std::array<int, NumSize> arr1;
//	std::array<int, NumSize> arr2;
//	std::array<int, NumSize> arr3;
//
//	std::generate(arr1.begin(), arr1.end(), [&]() {
//		return dis(gen);
//		});
//
//	std::generate(arr2.begin(), arr2.end(), [&]() {
//		return dis(gen);
//		});
//
//	timer.onTimer(0);
//	for (size_t i{ 0 }; i < NumSize; ++i)
//	{
//		arr3[i] = arr1[i] + arr2[i];
//	}
//	timer.offTimer(0);
//
//	
//
////#pragma omp parallel for schedule(static, 2) num_threads(3)
////	for (int i{ 0 }; i < 12; ++i)
////	{
////		int tID{ omp_get_thread_num() };
////		printf("[%d] by thread %d\n", i, tID);
////	}
//
////#pragma omp parallel for schedule(dynamic, 1) num_threads(3)
////	for (int i{ 0 }; i < 12; ++i)
////	{
////		int tID{ omp_get_thread_num() };
////		printf("[%d] by thread %d\n", i, tID);
////		std::this_thread::sleep_for(std::chrono::microseconds(1));
////	}
//
////#pragma omp parallel for schedule(guided, 1) num_threads(3)
////	for (int i{ 0 }; i < 12; ++i)
////	{
////		int tID{ omp_get_thread_num() };
////		printf("[%d] by thread %d\n", i, tID);
////		std::this_thread::sleep_for(std::chrono::microseconds(1));
////	}
//
//	//omp_set_nested(1);
//
//
//#pragma omp parallel num_threads(4)
//	{
//		int parentID = omp_get_thread_num();
//		printf("Lv 1 - Thread %d\n", parentID);
//
//#pragma omp parallel num_threads(2)
//		{
//			printf("\tLv 2 - Thread %d of %d\n", omp_get_thread_num(), parentID);
//		}
//	}
//
//	// Check reulsts
//	
//	/*for (int i{ 0 }; i < 10; ++i)
//	{
//		if (bin1[i] != bin2[i])
//		{
//			std::cout << "not match result!\n";
//			break;
//		}
//	}*/
//
//
//	timer.printTimer();
//	EXIT_WIHT_KEYPRESS;
//}
