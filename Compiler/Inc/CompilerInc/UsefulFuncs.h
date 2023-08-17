//
// Created by Сергей Слепышев on 07.08.2023.
//

#ifndef DSP_GPU_COMPILER_USEFULFUNCS_H
#define DSP_GPU_COMPILER_USEFULFUNCS_H

#include <stdlib.h>
#include "dStack.h"

#define NONE (-1)

int compareStrIntChar(const int a[], const char b[]);
unsigned char getConst10D(const int op[]);
unsigned char getConst16D(const int op[]);
void putZeroes(void* dst, unsigned size);
int searchFor(Stack *ptrNames, int op[], unsigned size);

#endif //DSP_GPU_COMPILER_USEFULFUNCS_H

