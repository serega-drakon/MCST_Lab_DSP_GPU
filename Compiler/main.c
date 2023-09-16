//
// Created by Сергей Слепышев on 03.08.2023.
//

#include <stdio.h>
#include "Compiler.h"

int main(){
    FILE* input = fopen("../Data/input.txt", "r");
    FILE* output = fopen("../Data/output.txt", "w");

    CompilerStates state;
    //state = compileTextToText(input, output);
    state = compileTextTo(input, output, printProgramFromStackToFile);

    fclose(input);
    fclose(output);
    return 0;
}