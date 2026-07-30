#include <iostream>
#include <thread>
#include <mutex>
#include <vector>

class Account
{
public:
    int id;
    int balance;
    std::mutex m;

    Account(int id, int balance) : id(id), balance(balance) {}
};

void transfer(Account& from, Account& to, int amount)
{
    std::scoped_lock<std::mutex, std::mutex> lock{ from.m, to.m };

    from.balance -= amount;
    to.balance += amount;
}

int deadlock()
{
    Account acc1{ 1, 10000 };
    Account acc2{ 2, 10000 };

    // 쓰레드 1: acc1 -> acc2로 1원씩 10000번 이체
    std::thread t1{ [&]() {
        for (int i{ 0 }; i < 10000; ++i) {
            transfer(acc1, acc2, 1);
        }
        } };

    // 쓰레드 2: acc2 -> acc1로 1원씩 10000번 이체
    std::thread t2{ [&]() {
        for (int i{ 0 }; i < 10000; ++i) {
            transfer(acc2, acc1, 1);
        }
        } };

    t1.join();
    t2.join();

    std::cout << "이체 완료!\n";
    std::cout << "계좌 1 잔액: " << acc1.balance << "\n";
    std::cout << "계좌 2 잔액: " << acc2.balance << "\n";

    return 0;
}