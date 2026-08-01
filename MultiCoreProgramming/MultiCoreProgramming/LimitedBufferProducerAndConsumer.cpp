#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <vector>
#include <chrono>

#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <vector>
#include <chrono>

void producer(int id, std::queue<int>& jobQueue, size_t max_size, std::mutex& mtx, std::condition_variable& cv_not_full, std::condition_variable& cv_not_empty)
{
	for (int i = 1; i <= 15; ++i)
	{
		std::this_thread::sleep_for(std::chrono::milliseconds(50));
		int data = id * 100 + i;

		std::unique_lock<std::mutex> lock{ mtx };
		cv_not_full.wait(lock, [&]()
			{ return jobQueue.size() < max_size; });

		jobQueue.push(data);
		lock.unlock();

		cv_not_empty.notify_one();

		std::cout
			<< "[생산자 " << id << "] 작업 등록: " << data
			<< " (현재 큐 크기: " << jobQueue.size() << ")" << std::endl;
	}
}

void consumer(int id, std::queue<int>& jobQueue, std::mutex& mtx, std::condition_variable& cv_not_full, std::condition_variable& cv_not_empty, const bool& finished)
{
	while (true)
	{
		int data = 0;

		std::unique_lock<std::mutex> lock{ mtx };
		cv_not_empty.wait(lock, [&]()
			{ return !jobQueue.empty() || finished; });

		if (jobQueue.empty() && finished)
			break;

		data = jobQueue.front();
		jobQueue.pop();
		lock.unlock();
		cv_not_full.notify_one();

		std::this_thread::sleep_for(std::chrono::milliseconds(150));
		std::cout << "[소비자 " << id << "] 작업 처리 완료: " << data << std::endl;
	}
}

int main()
{
	std::queue<int> jobQueue;
	std::mutex mtx;

	std::condition_variable cv_not_full;
	std::condition_variable cv_not_empty;

	bool finished = false;
	size_t max_size = 5;

	std::vector<std::thread> producers;
	std::vector<std::thread> consumers;

	for (int i = 1; i <= 2; ++i)
	{
		producers.emplace_back(producer, i, std::ref(jobQueue), max_size, std::ref(mtx), std::ref(cv_not_full), std::ref(cv_not_empty));
	}

	for (int i = 1; i <= 2; ++i)
	{
		consumers.emplace_back(consumer, i, std::ref(jobQueue), std::ref(mtx), std::ref(cv_not_full), std::ref(cv_not_empty), std::ref(finished));
	}

	for (auto& p : producers)
	{
		p.join();
	}

	{
		std::lock_guard<std::mutex> lock(mtx);
		finished = true;
	}

	cv_not_empty.notify_all();

	for (auto& c : consumers)
	{
		c.join();
	}

	std::cout << "모든 제한 버퍼 작업이 안전하게 완수되었습니다!" << std::endl;
	return 0;
}