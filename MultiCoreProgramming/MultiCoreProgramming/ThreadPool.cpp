#ifndef THREAD_POOL_H
#define THREAD_POOL_H

#include <vector>
#include <queue>
#include <thread>
#include <mutex>
#include <condition_variable>
#include <future>
#include <functional>
#include <type_traits>
#include <stdexcept>

class ThreadPool
{
private:
    std::vector<std::thread> workers;
    std::queue<std::function<void()>> jobQueue;

    std::mutex mtx;
    std::condition_variable cv;
    bool stop{ false };

public:
    explicit ThreadPool(size_t numThreads = std::thread::hardware_concurrency())
    {
        workers.reserve(numThreads);

        for (size_t i{ 0 }; i < numThreads; ++i)
            workers.emplace_back(&ThreadPool::workerThread, this);
    }

    ~ThreadPool()
    {
        std::unique_lock<std::mutex> lock(mtx);
        stop = true;
        lock.unlock();

        cv.notify_all();

        for (std::thread& worker : workers)
        {
            if (worker.joinable())
                worker.join();
        }
    }

    template <typename F, typename... Args>
    std::future<std::invoke_result_t<F, Args...>> enqueueJob(F&& func, Args&&... args)
    {
        using returnType = std::invoke_result_t<F, Args...>;

        auto task{ std::make_shared<std::packaged_task<returnType()>>(
            [func = std::forward<F>(func), ...args = std::forward<Args>(args)]() mutable
            {
                return std::invoke(std::move(func), std::move(args)...);
            }
        ) };

        std::future<returnType> res{ task->get_future() };

        std::unique_lock<std::mutex> lock{ mtx };

        if (stop)
            throw std::runtime_error("threadPool stop");

        jobQueue.emplace([task]() {
            (*task)();
            });

        lock.unlock();

        cv.notify_one();

        return res;
    }

private:
    void workerThread()
    {
        while (true)
        {
            std::unique_lock<std::mutex> lock(mtx);
            cv.wait(lock, [this]()
                {
                    return stop || jobQueue.empty();
                });

            if (stop && jobQueue.empty())
                break;

            std::function<void()> job{ std::move(jobQueue.front()) };
            jobQueue.pop();
            lock.unlock();

            job();
        }
    }
};

#endif // THREAD_POOL_H
