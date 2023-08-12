#ifndef PROCESSOR_EMULATOR_MEMORY_H
#define PROCESSOR_EMULATOR_MEMORY_H

#include <stdlib.h>

typedef struct Stack_ Stack;

void dStackErrorPrint(Stack *ptrStack);
int dStackErrorCheck(Stack *ptrStack);
Stack *dStackInit(u_int32_t size);
void *dStack_r(Stack *ptrStack, u_int32_t x);
void *dStack_w(Stack *ptrStack, u_int32_t x, const void *ptrValue);
void *push_dStack(Stack *ptrStack, const void *ptrValue);
void *pop_dStack(Stack *ptrStack);
void *getLast_dStack(Stack *ptrStack);
u_int32_t getsize_dStack(Stack *ptrStack);
void dStackFree(Stack *ptrStack);
void dStackReset(Stack *ptrStack);

#endif //PROCESSOR_EMULATOR_MEMORY_H
