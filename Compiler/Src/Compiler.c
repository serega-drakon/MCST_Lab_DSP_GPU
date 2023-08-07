//
// Created by Сергей Слепышев on 04.08.2023.
// здесь куски из моего старого компилятора для другого проца

#include <stdio.h>
#include <ctype.h>
#include <assert.h>
#include "Compiler.h"
#include "dStack.h"
#include "strings.h"
#include "encodings.h"
#include "UsefulFuncs.h"

#define OK 0
#define ERROR (-1)

#define MEM_CHECK(ptrMem, errorName) \
do{ if(ptrMem == NULL){printf(errorName); return ERROR;} } while(0)

#define ERROR_MSG(errorMsg, errorCode, lineNum) \
do { printf("Line %d: %s%s", lineNum, errorMsg, "\n");  \
return errorCode; } while(0)

#define ERROR_MSG_OP(errorMsg, errorCode, op, lineNum) \
do { printf("Line %d: %s%s", lineNum, errorMsg, "\n -> ");  \
for (int index = 0; op[index] != '\0'; index++) \
    printf("%c", op[index]);                    \
printf("\n");                                   \
return errorCode; } while(0)

///Набор динамических массивов, которые я использую
typedef struct Defines_{
    Stack* ptrLabelDefinedNames;       ///<имена меток
    Stack* ptrLabelDefinedValues;      ///<величины меток
    Stack* ptrLabelUsedNames;
    Stack* ptrLabelUsedValuesPtr;
} Defines;

///Конструктор
int definesInit(Defines *defs){
    const char error_msg[] = "defines memory allock error";
    defs->ptrLabelDefinedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelDefinedNames, error_msg);
    defs->ptrLabelDefinedValues = dStackInit(sizeof(char));
    MEM_CHECK(defs->ptrLabelDefinedValues, error_msg);
    defs->ptrLabelUsedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelUsedNames, error_msg);
    defs->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(defs->ptrLabelUsedValuesPtr, error_msg);
    return OK;
}

///Деструктор
void definesFree(struct Defines_ *def){
    dStackFree(def->ptrLabelDefinedNames);
    dStackFree(def->ptrLabelDefinedValues);
    dStackFree(def->ptrLabelUsedNames);
    const u_int32_t size = getsize_dStack(def->ptrLabelUsedValuesPtr);
    for(int i = 0; i < size; i++)
        dStackFree(*(void **) dStack_r(def->ptrLabelUsedValuesPtr, i));
    dStackFree(def->ptrLabelUsedValuesPtr);
}

OpTypes getType(const int op[]){

}

/// Подфункция getOp \n
/// 1 - залезли на 1char-symbol \n
/// 0 - не залезли
char checkStopCharGetOp(int c){
    switch(c){
        case '{': case '}': case '[': case ']':
        case ',': case '=':
            return 1;
        default:
            return 0;
    }
}

/// Получает операнд из потока ввода \n
/// Возвращает длину полученной строки
int getOp(FILE* input, unsigned int *ptrLineNum, int op[], unsigned int size){
    assert(input != NULL && ptrLineNum != NULL && op != NULL && size > 1);

    int c;
    int i = 0;
    while((c = getc(input)) == ' ' || c == '\t' || c == '\n')
        if(c == '\n') (*ptrLineNum)++;

    if(c != EOF) {
        do {
            op[i++] = c;
            c = getc(input);
        } while (i < (size - 1) && c != ' ' && c != '\n' && c != '\t' && !checkStopCharGetOp(c) && c != EOF);
    }

    if(checkStopCharGetOp(c) || c == '\n' || c == EOF)
        ungetc(c, input);

    op[i] = '\0';
    return i;
}

typedef enum getFrameStates_{
    GetFrameEnd = -1, ///< если конец достигнут
    GetFrameOk = 0 ///< если конец не достигнут
} getFrameStates;

getFrameStates getControlFrame(FILE* input, Stack *output, unsigned int *ptrLineNum){

}

getFrameStates getInsnFrame(FILE* input, Stack *output, Defines *defs, unsigned int *ptrLineNum){
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}


//FIXME: считать фрейм и проверить, достигнут ли конец
getFrameStates getFrame(FILE *input, Stack *output, Defines *defs, unsigned int *ptrLineNum){

    return GetFrameOk;
}

CompilerStates compileFileToStack(FILE* input, Stack* output){
    Defines defs;
    int defState = definesInit(&defs);
    if(defState == ERROR)
        return CompilerErrorMemAlloc;
    getFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;
    do {
        frameState = getFrame(input, output, &defs, &lineNum);
        i++;
    } while(i < FRAMES_COUNT && frameState == GetFrameOk);
    if(i == FRAMES_COUNT && frameState == GetFrameOk) {
        int op[MAX_OP];
        unsigned int size = getOp(input, &lineNum, op, MAX_OP);
        if(size > 0)
            ERROR_MSG_OP("Error: Out of range, max count of frames has reached \n",
                         CompilerErrorOverflowFrames, op, lineNum);
    }
    return CompilerOK;
}

void printProgramFromStackToFile(Stack* input, FILE* output){

}

CompilerStates compileTextToText(FILE* input, FILE* output){ //FIXME
    CompilerStates state;
    Stack* ptrProgram = dStackInit(INSN_SIZE);
    state = compileFileToStack(input, ptrProgram);
    if(state == CompilerOK)
        printProgramFromStackToFile(ptrProgram, output);
    dStackFree(ptrProgram);
    return state;
}