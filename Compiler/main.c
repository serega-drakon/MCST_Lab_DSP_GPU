//
// Created by Сергей Слепышев on 03.08.2023.
//

#include <stdio.h>
#include "Compiler.h"

int main(){
    FILE* input = fopen("../input.txt", "r");
    FILE* output = fopen("../output.txt", "w");

    //CompilerStates state;
    //state = compileTextToText(input, output);

    fclose(input);
    fclose(output);
    return 0;
}