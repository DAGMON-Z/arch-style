/* Added by F6 only (gcc -include): print output right away, not at the end. */
#include <stdio.h>
__attribute__((constructor)) static void f6_flush(void) {
    setvbuf(stdout, NULL, _IONBF, 0);
}
