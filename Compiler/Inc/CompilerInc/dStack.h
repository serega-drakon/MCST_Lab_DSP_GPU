#ifndef PROCESSOR_EMULATOR_MEMORY_H
#define PROCESSOR_EMULATOR_MEMORY_H

#include "arm/types.h"

typedef struct Stack_ Stack;

void dStackErrorPrint(Stack *ptrStack);
int dStackErrorCheck(Stack *ptrStack);
Stack *dStackInit(u_int32_t size);
char *dStack_r_char(Stack *ptrStack, u_int32_t xOfUnit, u_int32_t xOfChar);
int32_t *dStack_r_int32(Stack *ptrStack, u_int32_t xOfUnit, u_int32_t xOfInt32);
void *dStack_r(Stack *ptrStack, u_int32_t x);
void *dStack_w(Stack *ptrStack, u_int32_t x, const void *ptrValue);
void *push_dStack(Stack *ptrStack, const void *ptrValue);
void *pop_dStack(Stack *ptrStack);
void *getLast_dStack(Stack *ptrStack);
u_int32_t getsize_dStack(Stack *ptrStack);
void dStackFree(Stack *ptrStack);

#endif //PROCESSOR_EMULATOR_MEMORY_H
