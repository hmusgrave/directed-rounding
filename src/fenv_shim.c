#include <fenv.h>

#pragma STDC FENV_ACCESS ON

int fenv_get_round(void) {
    return fegetround();
}

void fenv_set_round(int mode) {
    fesetround(mode);
}
