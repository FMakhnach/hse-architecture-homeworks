#include <fstream>
#include <iostream>
#include <set>
#include <string>
#include <omp.h>

namespace glob {
	// Lower bound of checked values interval.
	const int LOWER_BOUND = 1e3;
	// Upper bound of checked values interval.
	const int UPPER_BOUND = 1e9;
	// Parameter n -- number we multiply every number from interval on.
	int n;
	// Lower bound of parameter n.
	const int n_lower = 1;
	// Upper bound of parameter n.
	const int n_upper = 10;
	// Number of threads.
	size_t num_of_threads;
	// Set of such x's that follow {digits x} = {digits x * n}.
	std::set<int> result_set;
	// Bit mask for each digit (e.g. 1 -> 0000000010, 7 -> 0010000000).
	uint16_t digit_masks[10];
}

// Calculating bit masks (the only non-zero bit is on the i-th position for i in [0; 9]
void PrecomputeDigitMasks() {
	for (size_t i = 0; i < 10; ++i) {
		glob::digit_masks[i] = 1 << i;
	}
}

// Calculates a digit mask for num. Mask is 16 bits where 10 are valueable.
// The 1 on i-th position means that i appears in decimat representation of num.
uint16_t GetBitmapOfDigits(int64_t num) {
	uint16_t bitmap = 0;
	while (num != 0) {
		// Marking the bits which represent each digit.
		bitmap |= glob::digit_masks[num % 10];
		// Checking every digit.
		num /= 10;
	}
	return bitmap;
}

// Checking our condition {digits num} = {digits num * n}.
void CheckNum(int num) {
	// Calculating the mask for num and num * n.
	uint16_t num_map = GetBitmapOfDigits(num);
	uint16_t prod_map = GetBitmapOfDigits(static_cast<int64_t>(num) * glob::n);

	if (num_map == prod_map) {
#pragma omp critical
		{
			// If num satisfies the condition, then -num does too
			glob::result_set.insert(-num);
			glob::result_set.insert(num);
		}
	}
}

void CalculateMultiThread() {
#pragma omp parallel for num_threads(glob::num_of_threads)
	for (int i = glob::LOWER_BOUND; i < glob::UPPER_BOUND; ++i) {
		CheckNum(i);
	}
}

// Reading N from standard input.
bool TryReadN() {
	std::cout << "Please, enter N: ";
	std::cin >> glob::n;
	return glob::n_lower < glob::n&& glob::n < glob::n_upper;
}

// Reading number of threads from standard input.
bool TryReadNumberOfThreads() {
	std::cout << "Please, enter number of threads: ";
	std::cin >> glob::num_of_threads;
	return 0 < glob::num_of_threads && glob::num_of_threads <= omp_get_max_threads();
}

void WriteSetToFile(const std::set<int>& set, const std::string& path) {
	std::ofstream out;
	out.open(path);
	if (out.is_open()) {
		for (int i : set) {
			out << i << std::endl;
		}
	}
	out.close();
}

int main() {
	// Calculating the bitmasks, which we'll need in function GetBitmapOfDigits.
	PrecomputeDigitMasks();
	bool reading_successful = TryReadN();
	if (reading_successful == false) {
		std::cerr << "Wrong input! n must be a integer in range [2; 9]." << std::endl;
		return 1;
	}
	reading_successful = TryReadNumberOfThreads();
	if (reading_successful == false) {
		std::cerr << "Wrong input! Num of threads cannot be less than 1 or more than "
			<< omp_get_max_threads() << "!" << std::endl;
		return 1;
	}
	CalculateMultiThread();
	WriteSetToFile(glob::result_set, "out.txt");
	return 0;
}
