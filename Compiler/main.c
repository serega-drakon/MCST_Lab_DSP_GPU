//
// Created by Сергей Слепышев on 03.08.2023.
//

#include <stdio.h>
//#include "Compiler/Compiler.h"

//void printCompilerState(CompilerStates state){

//}

int main(){
    FILE* input = fopen("../input.txt", "r");
    FILE* output = fopen("../output.txt", "w");

    //CompilerStates state;
    //state = compileTextToText(input, output);
    //printCompilerState(state);

    int a,b,c;
    a = getc(input);
    ungetc(a, input);
    b = getc(input);
    c = EOF;

    fclose(input);
    fclose(output);
    return 0;
}