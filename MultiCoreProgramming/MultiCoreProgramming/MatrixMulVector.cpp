#include <stdio.h>
#include <stdlib.h>
#include <omp.h>
#include "DS_timer.h"
#include "DS_definitions.h"

#define m (10000)
#define n (10000)

#define GenFloat (rand() % 100 + ((float)(rand() % 100) / 100.0))
void genRandomInput();

float A[m][n];
float X[n];
float Y_serial[m];
float Y_parallel[m];
float Y_myParallel[m];

int MatrixMulVector(int argc, char* argv[])
{
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
	for (int i = 0; i < m; i++) {
		Y_serial[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_serial[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(0);

	// Parallel code
	timer.onTimer(1);
#pragma omp parallel for num_threads(1)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(1);


	timer.onTimer(2);
#pragma omp parallel for num_threads(2)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(2);


	timer.onTimer(3);
#pragma omp parallel for num_threads(4)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(3);

	timer.onTimer(4);
#pragma omp parallel for num_threads(8)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(4);

	timer.onTimer(5);
#pragma omp parallel for num_threads(16)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(5);

	timer.onTimer(6);
#pragma omp parallel for num_threads(32)
	for (int i = 0; i < m; i++) {
		Y_parallel[i] = 0.0;
		for (int j = 0; j < n; j++) {
			Y_parallel[i] += A[i][j] * X[j];
		}
	}
	timer.offTimer(6);

	// Check reulsts
	LOOP_I(m) {
		if (Y_serial[i] != Y_parallel[i]) {
			printf("Results are not matched :(");
			EXIT_WIHT_KEYPRESS;
		}
	}

	timer.printTimer();
	EXIT_WIHT_KEYPRESS;
}

void genRandomInput(void) {
	// A matrix
	LOOP_INDEX(row, m) {
		LOOP_INDEX(col, n) {
			A[row][col] = GenFloat;
		}
	}

	LOOP_I(n)
		X[i] = GenFloat;

	memset(Y_serial, 0, sizeof(float) * m);
	memset(Y_parallel, 0, sizeof(float) * m);
}