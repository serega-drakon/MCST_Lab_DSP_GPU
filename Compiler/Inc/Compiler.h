//
// Created by Сергей Слепышев on 04.08.2023.
//

#ifndef DSP_GPU_COMPILER_COMPILER_H
#define DSP_GPU_COMPILER_COMPILER_H

#include <stdio.h>

#define FRAMES_COUNT 16
#define INSN_SIZE (2 * sizeof(char))
#define INSN_COUNT 16
#define CORES_COUNT 16
#define REG_COUNT 16
#define REG_SIZE (1 * sizeof(char))

#define MAX_OP 64

typedef enum CompilerStates_ {
    CompilerOK,
    CompilerErrorNullInput,
    CompilerErrorNullStack,
    CompilerErrorMemAlloc,
    CompilerErrorZeroFrameCount,
    CompilerErrorUserCode
} CompilerStates;

CompilerStates compileTextToText(FILE* input, FILE* output);
CompilerStates compileTextToBin(FILE *input, FILE *output);
void printCompilerState(CompilerStates state);

#endif //DSP_GPU_COMPILER_COMPILER_H
