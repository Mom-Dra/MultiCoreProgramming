#include <iostream>
#include <thread>
#include <vector>
#include <atomic>
#include <chrono>

void increment_worker(int& normal_counter, std::atomic<int>& atomic_counter)
{
    for (int i{ 0 }; i < 10000; ++i)
    {
        normal_counter++;
        atomic_counter.fetch_add(1, std::memory_order_relaxed);
    }
}

void producer(int& payload_data, std::atomic<bool>& is_ready)
{
    payload_data = 42;
    is_ready.store(true, std::memory_order_release);
}

void consumer(const int& payload_data, std::atomic<bool>& is_ready)
{
    while (!is_ready.load(std::memory_order_acquire))
    {
    }

    std::cout << "[Consumer] 수신 완료! 데이터: " << payload_data << std::endl;
}

int memoryOrder() {
    std::cout << "=== Part 1: Race Condition vs std::atomic ===" << std::endl;
    {
        int normal_counter = 0;
        std::atomic<int> atomic_counter{ 0 };

        std::vector<std::thread> threads;
        for (int i = 0; i < 4; ++i)
        {
            threads.push_back(std::thread(increment_worker, std::ref(normal_counter), std::ref(atomic_counter)));
        }

        for (auto& t : threads)
        {
            t.join();
        }

        std::cout << "일반 카운터 결과 (Race 발생): " << normal_counter << " (기대값: 40000)" << std::endl;
        std::cout << "원자적 카운터 결과 (성공): " << atomic_counter.load() << std::endl;
    }

    std::cout << "\n=== Part 2: Acquire - Release 동기화 ===" << std::endl;
    {
        int payload_data = 0;
        std::atomic<bool> is_ready{ false };

        std::thread t1(producer, std::ref(payload_data), std::ref(is_ready));
        std::thread t2(consumer, std::cref(payload_data), std::ref(is_ready));

        t1.join();
        t2.join();
    }

    return 0;
}