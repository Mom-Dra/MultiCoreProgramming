#include <iostream>
#include <vector>
#include <thread>
#include <mutex>
#include <numeric>

void accumulateSum(const std::vector<int>& data, int start, int end, int& totalSum, std::mutex& mtx)
{
    int localSum{ 0 };

    for (int i{ start }; i < end; ++i)
    {
        localSum += data[i];
    }

    std::lock_guard<std::mutex> lock{ mtx };
    totalSum += localSum;
}

int sum()
{
    constexpr int num_threads{ 4 };

    std::vector<int> data(10000);
    std::iota(data.begin(), data.end(), 1);

    int totalSum{ 0 };
    std::mutex mtx;
    std::vector<std::thread> threads;

    int chunkSize = data.size() / num_threads;

    for (int i{ 0 }; i < num_threads; ++i)
    {
        int start{ i * chunkSize };
        int end{ start + chunkSize };

        threads.emplace_back(
            accumulateSum,
            std::cref(data),
            start,
            end,
            std::ref(totalSum),
            std::ref(mtx));
    }

    for (auto& t : threads)
    {
        t.join();
    }

    std::cout << "Sum: " << totalSum;

    return 0;
}