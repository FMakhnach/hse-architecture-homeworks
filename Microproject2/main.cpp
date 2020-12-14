#include <iostream>
#include <random>
#include <sstream>
#include <string>
#include <vector>

#include <chrono>
#include <thread>
#include <mutex>

#define SINGLE_ROOMS_NUM 10
#define DOUBLE_ROOMS_NUM 15

std::mt19937 mrand{101};

enum class Person {
    Dame, Gentleman
};

std::string ToString(Person person) {
    return person == Person::Dame ? "Dame" : "Gentleman";
}

namespace Hotel {
    int single_rooms_empty = SINGLE_ROOMS_NUM;
    int single_rooms_with_dame = 0;
    int single_rooms_with_gentleman = 0;
    std::mutex single_rooms_mutex;

    int double_rooms_empty = DOUBLE_ROOMS_NUM;
    std::mutex double_rooms_empty_mutex;

    int double_rooms_with_one_dame = 0;
    int double_rooms_with_two_dames = 0;
    std::mutex double_room_dames_mutex;

    int double_rooms_with_one_gentleman = 0;
    int double_rooms_with_two_gentlemen = 0;
    std::mutex double_room_gentlemen_mutex;


    bool CheckDoubleRoomWithDame(std::stringstream &msg) {
        std::lock_guard<std::mutex> lock(double_room_dames_mutex);
        if (double_rooms_with_one_dame > 0) {
            msg << "Dame moved into a double room with other dame.\n";
            --double_rooms_with_one_dame;
            ++double_rooms_with_two_dames;
            return true;
        }
        return false;
    }

    bool CheckDoubleRoomWithGentleman(std::stringstream &msg) {
        std::lock_guard<std::mutex> lock(double_room_gentlemen_mutex);
        if (double_rooms_with_one_gentleman > 0) {
            msg << "Gentleman moved into a double room with other gentleman.\n";
            --double_rooms_with_one_gentleman;
            ++double_rooms_with_two_gentlemen;
            return true;
        }
        return false;
    }

    bool CheckEmptyDoubleRoom(std::stringstream &msg, Person person) {
        std::lock_guard<std::mutex> lock(double_rooms_empty_mutex);
        if (double_rooms_empty > 0) {
            msg << ToString(person) << " moved into an empty double room.\n";
            --double_rooms_empty;
            if (person == Person::Dame) {
                std::lock_guard<std::mutex> lock_dame(double_room_dames_mutex);
                ++double_rooms_with_one_dame;
            } else {
                std::lock_guard<std::mutex> lock_gentleman(double_room_gentlemen_mutex);
                ++double_rooms_with_one_gentleman;
            }
            return true;
        }
        return false;
    }

    bool CheckEmptySingleRoom(std::stringstream &msg, Person person) {
        std::lock_guard<std::mutex> lock(single_rooms_mutex);
        if (single_rooms_empty > 0) {
            msg << ToString(person) << " moved into an empty single room.\n";
            --single_rooms_empty;
            if (person == Person::Dame) {
                ++single_rooms_with_dame;
            } else {
                ++single_rooms_with_gentleman;
            }
            return true;
        }
        return false;
    }

    void TryMoveIn(Person person, int32_t thread_num) {
        std::stringstream msg;
        msg << "Thread #" << thread_num << ": ";
        // Looking for a room.
        bool managed_to_move_in = person == Person::Dame
                                  ? CheckDoubleRoomWithDame(msg)
                                  : CheckDoubleRoomWithGentleman(msg);
        managed_to_move_in = managed_to_move_in
                          || CheckEmptyDoubleRoom(msg, person)
                          || CheckEmptySingleRoom(msg, person);

        if (!managed_to_move_in) {
            msg << ToString(person) << " haven't found a room and leaves the hotel.\n";
        }
        std::cout << msg.str();
    }



    void LeaveSingleRoom(int32_t thread_num, Person person) {
        std::lock_guard<std::mutex> lock(single_rooms_mutex);
        if ((person == Person::Dame) && (single_rooms_with_dame > 0)) {
            --single_rooms_with_dame;
            ++single_rooms_empty;
            std::cout << "Thread #" + std::to_string(thread_num) + ": Dame left single room.\n";
        } else if (single_rooms_with_gentleman > 0) {
            --single_rooms_with_gentleman;
            ++single_rooms_empty;
            std::cout << "Thread #" + std::to_string(thread_num) + ": Gentleman left single room.\n";
        }
    }

    void LeaveDoubleRoomDame(int32_t thread_num, bool check_full_room) {
        std::lock_guard<std::mutex> lock(double_room_dames_mutex);
        if (check_full_room && (double_rooms_with_two_dames > 0)) {
            // Dame leaves double room where 2 dames were.
            --double_rooms_with_two_dames;
            ++double_rooms_with_one_dame;
            std::cout << "Thread #" + std::to_string(thread_num) + ": Dame left double room.\n";
        } else if (double_rooms_with_one_dame > 0) {
            // Dame leaves double room where only 1 dame was.
            --double_rooms_with_one_dame;
            ++double_rooms_empty;
            std::cout << "Thread #" + std::to_string(thread_num) +
                         ": Dame left double room. This room is now empty.\n";
        }
    }

    void LeaveDoubleRoomGentleman(int32_t thread_num, bool check_full_room) {
        std::lock_guard<std::mutex> lock(double_room_gentlemen_mutex);
        if (check_full_room && (double_rooms_with_two_gentlemen > 0)) {
            // Gentleman leaves double room where 2 gentlemen were.
            --double_rooms_with_two_gentlemen;
            ++double_rooms_with_one_gentleman;
            std::cout << "Thread #" + std::to_string(thread_num) + ": Gentleman left double room.\n";
        } else if (double_rooms_with_one_gentleman > 0) {
            // Gentleman leaves double room where only 1 gentleman was.
            --double_rooms_with_one_gentleman;
            ++double_rooms_empty;
            std::cout << "Thread #" + std::to_string(thread_num) +
                         ": Gentleman left double room. This room is now empty.\n";
        }
    }

    void LeaveDoubleRoom(int32_t thread_num, Person person) {
        bool check_full_room = mrand() % 2;
        if (person == Person::Dame) {
            LeaveDoubleRoomDame(thread_num, check_full_room);
        } else {
            LeaveDoubleRoomGentleman(thread_num, check_full_room);
        }
    }


    void LeaveRandomRoom(int32_t thread_num) {
        // Choosing single or double room.
        bool is_single = mrand() % 2;
        // Choosing dame or gentleman.
        auto person = (Person)(mrand() % 2);
        if (is_single) {
            LeaveSingleRoom(thread_num, person);
        } else {
            LeaveDoubleRoom(thread_num, person);
        }
    }
}

size_t sleep_duration_ms;

void ThreadLogic(uint32_t thread_num, uint32_t num_of_iterations) {
    for (uint32_t i = 0; i < num_of_iterations; ++i) {
        // 0 for leaving the hotel, 1-2 for moving in.
        auto choice = mrand() % 3;
        if (choice == 0) {
            Hotel::LeaveRandomRoom(thread_num);
        } else {
            auto person = (Person) (mrand() % 2);
            Hotel::TryMoveIn(person, thread_num);
        }

        if (sleep_duration_ms != 0) {
            std::this_thread::sleep_for(std::chrono::milliseconds(sleep_duration_ms));
        }
    }
}

// Launches the threads.
void CalculateMultiThread(uint32_t num_of_threads, uint32_t num_of_iterations) {
    auto *threads = new std::thread[num_of_threads];

    // Launching the threads.
    for (uint32_t i = 0; i < num_of_threads; ++i) {
        threads[i] = std::thread(ThreadLogic, i + 1, num_of_iterations);
    }
    // Waiting until each of them will finish.
    for (uint32_t i = 0; i < num_of_threads; ++i) {
        threads[i].join();
    }

    delete[] threads;
}

int main() {
    uint32_t num_of_threads = 0;
    std::cout << "Please, enter number of threads: ";
    std::cin >> num_of_threads;
    if (num_of_threads == 0 || num_of_threads > std::thread::hardware_concurrency()) {
        num_of_threads = std::thread::hardware_concurrency();
        std::cout << "Value " << num_of_threads << " is invalid. Default value ("
                  << std::thread::hardware_concurrency() << ") is set.\n";
    }

    sleep_duration_ms = 0;
    std::cout << "Please, enter interval between messages (ms): ";
    std::cin >> sleep_duration_ms;

    int num_of_iterations = 0;
    std::cout << "Please, enter number of iterations per thread: ";
    std::cin >> num_of_iterations;
    if (num_of_iterations < 0) {
        num_of_iterations = 100;
        std::cout << "Value " << num_of_iterations << " is invalid. Default value (100) is set.\n";
    }
    std::cout << '\n';

    try {
        CalculateMultiThread(num_of_threads, num_of_iterations);
    } catch (std::exception &e) {
        std::cout << e.what() << std::endl;
    }

    return 0;
}
