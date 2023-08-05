//
// Created by Сергей Слепышев on 03.08.2023.
//

#include <stdio.h>
#include "Compiler/Compiler.h"

int main(){
    FILE* input = NULL;
    FILE* output = NULL;

    CompilerStates state;
    state = compileTextToText(input, output);

    return 0;
}