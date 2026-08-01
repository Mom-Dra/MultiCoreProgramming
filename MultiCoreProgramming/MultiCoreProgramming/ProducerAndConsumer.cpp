#include <iostream>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <queue>
#include <vector>
#include <chrono>

void producer(int id, std::queue<int>& jobQueue, std::mutex& mtx, std::condition_variable& cv)
{
    for (int i{ 1 }; i <= 10; ++i)
    {
        std::this_thread::sleep_for(std::chrono::milliseconds(100));

        int data{ id * 100 + i };

        {
            std::lock_guard<std::mutex> lock{ mtx };
            jobQueue.push(data);
        }

        cv.notify_one();

        std::cout << "[producer " << id << "] " << data << std::endl;
    }
}

void consumer(int id, std::queue<int>& jobQueue, std::mutex& mtx, std::condition_variable& cv, const bool& finished)
{
    while (true)
    {
        std::unique_lock<std::mutex> lock{ mtx };
        cv.wait(lock, [&]
            { return !jobQueue.empty() || finished; });

        if (jobQueue.empty() && finished)
            break;

        int data{ jobQueue.front() };
        jobQueue.pop();

        lock.unlock();

        std::this_thread::sleep_for(std::chrono::milliseconds(150));
        std::cout << "[consumer " << id << "] " << data << std::endl;
    }
}

int producerAndConsumer()
{
    std::queue<int> jobQueue;
    std::mutex mtx;
    std::condition_variable cv;
    bool finished = false;

    std::vector<std::thread> producers;
    std::vector<std::thread> consumers;

    for (int i{ 1 }; i <= 2; ++i)
    {
        producers.emplace_back(producer, i, std::ref(jobQueue), std::ref(mtx), std::ref(cv));
    }

    for (int i{ 1 }; i <= 2; ++i)
    {
        consumers.emplace_back(consumer, i, std::ref(jobQueue), std::ref(mtx), std::ref(cv), std::ref(finished));
    }

    for (auto& p : producers)
    {
        p.join(); // [8]
    }

    {
        std::lock_guard<std::mutex> lock(mtx);
        finished = true;
    }

    for (auto& c : consumers)
    {
        c.join();
    }

    std::cout << "end" << std::endl;
    return 0;
}