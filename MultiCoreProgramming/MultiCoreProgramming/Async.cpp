#include <iostream>
#include <thread>
#include <future>
#include <stdexcept>
#include <chrono>

void calculate_factorial(int n, std::promise<long long> pr)
{
    try
    {
        if (n < 0) 
        {
            throw std::invalid_argument("음수 값은 팩토리얼을 계산할 수 없습니다!");
        }

        long long result = 1;
        for (int i = 1; i <= n; ++i) result *= i;

        pr.set_value(result);
    }
    catch (...) {
        pr.set_exception(std::current_exception());
    }
}

double safe_divide(double numerator, double denominator)
{
    if (denominator == 0.0) {
        throw std::runtime_error("0으로 나눌 수 없습니다 (Division by zero)!");
    }

    return numerator / denominator;
}

long long sum_range(int start, int end)
{
    long long sum = 0;
    for (int i = start; i <= end; ++i) sum += i;
    return sum;
}

int main()
{
    std::cout << "=== Part 1: std::promise와 수동 예외 전파 [14, 15] ===" << std::endl;
    {
        std::promise<long long> pr1;
        std::future<long long> fut1 = pr1.get_future();
        std::thread t1(calculate_factorial, 5, std::move(pr1));
        t1.join();
        std::cout << "5! 계산 결과: " << fut1.get() << std::endl;

        std::promise<long long> pr2;
        std::future<long long> fut2 = pr2.get_future();
        std::thread t2(calculate_factorial, -5, std::move(pr2));
        t2.join();

        try
        {
            long long res = fut2.get();
            std::cout << "결과: " << res << std::endl;
        }
        catch (const std::exception& e) 
        {
            std::cerr << "[성공] 스레드 내부 예외 감지 -> " << e.what() << std::endl;
        }
    }

    std::cout << "\n=== Part 2: std::packaged_task를 활용한 자동 포장 [17] ===" << std::endl;
    {
        std::packaged_task<double(double, double)> task{ safe_divide };
        std::future<double> fut = task.get_future(); 

        std::thread calc_thread(std::move(task), 10.0, 0.0);
        calc_thread.join();

        try
        {
            double res = fut.get();
            std::cout << "나눗셈 결과: " << res << std::endl;
        }
        catch (const std::exception& e) {
            std::cerr << "[성공] 나눗셈 예외 감지 -> " << e.what() << std::endl;
        }
    }

    std::cout << "\n=== Part 3: std::async를 이용한 고수준 비동기 추상화 [20] ===" << std::endl;
    {
        std::future<long long> fut = std::async(std::launch::async, sum_range, 1, 500);

        long long main_sum = sum_range(501, 1000);
        long long async_sum = fut.get();

        std::cout << "1~1000 병렬 합산 완료: " << (main_sum + async_sum) << " (기대값: 500500)" << std::endl;
    }

    return 0;
}