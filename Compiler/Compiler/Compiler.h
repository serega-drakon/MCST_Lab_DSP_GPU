//
// Created by Сергей Слепышев on 04.08.2023.
//

#ifndef MCST_LAB_DSP_GPU_COMPILER_H
#define MCST_LAB_DSP_GPU_COMPILER_H

typedef enum CompilerStates_ {
    OK,
    Error
} CompilerStates;

CompilerStates compileTextToText(FILE* input, FILE* output);

#endif //MCST_LAB_DSP_GPU_COMPILER_H
