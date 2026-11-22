// Added by F6 only (g++ -include), never part of your code or submissions.
// Turns on "flush after every output" before main() starts, so when you type
// input by hand, the answers appear right away instead of all at the end.
// (Fast I/O, sync_with_stdio(0) and cin.tie(0), keeps this setting.)
#include <iostream>
namespace {
struct F6Flush {
    F6Flush() {
        std::cout << std::unitbuf;
        std::cerr << std::unitbuf;
    }
} f6_flush;
}
