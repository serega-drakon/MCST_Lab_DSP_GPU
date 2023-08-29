//
// Created by Сергей Слепышев on 04.08.2023.
//

#ifndef DSP_GPU_COMPILER_COMPILER_H
#define DSP_GPU_COMPILER_COMPILER_H

#include <stdio.h>
#include "dStack.h"

#define INSN_SIZE (2 * sizeof(char))
#define INSN_COUNT 16
#define FRAMES_COUNT 64
#define CORES_COUNT 16
#define REG_COUNT 16
#define REG_SIZE (1 * sizeof(char))
#define RESERVED (0)

#define MAX_OP 64

typedef enum CompilerStates_ {
    CompilerOK,
    CompilerErrorNullInput,
    CompilerErrorNullStack,
    CompilerErrorMemAlloc,
    CompilerErrorZeroFrameCount,
    CompilerErrorUserCode
} CompilerStates;

CompilerStates compileFileToStack(FILE* input, Stack* output);
CompilerStates compileTextToText(FILE* input, FILE* output);
CompilerStates compileTextToBin(FILE *input, FILE *output);
CompilerStates compileTextToVerilog(FILE* input, FILE* output);
CompilerStates compileTextTo(FILE* input, FILE* output, void func(Stack*, FILE*));
void printProgramFromStackToFile(Stack* input, FILE* output);
void printProgramFromStackToBin(Stack* input, FILE* output);
void printProgramFromStackToVerilog(Stack* input, FILE* output);
void printCompilerState(CompilerStates state);

#endif //DSP_GPU_COMPILER_COMPILER_H
