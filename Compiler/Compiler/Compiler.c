//
// Created by Сергей Слепышев on 04.08.2023.
// здесь куски из моего старого компилятора для другого проца

#include <stdio.h>
#include <ctype.h>
#include <assert.h>
#include "Compiler.h"
#include "../Memory/dStack.h"

#define MEM_CHECK(ptrMem, errorName) \
do{ if(ptrMem == NULL){printf(errorName); return ERROR;} }while(0)

///Представления регистров %..
const char *registers_[] = { //емае пошло говно по трубам
        "r0",
        "r1",
        "r2",
        "r3",
        "r4",
        "r5",
        "r6",
        "r7",
        "r8",
        "r9",
        "r10",
        "r11",
        "r12",
        "r13",
        "r14",
        "r15"
};

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

///Сравнивает строки    \n
///Возвращет 1 если совпали, иначе - 0
int compareStrIntChar(const int a[], const char b[]){
    int j;
    int flag = 1;
    for(j = 0; flag && a[j] != '\0' && b[j] != '\0'; j++) {
        if (a[j] != b[j]) flag = 0;
    }
    if(flag && a[j] == '\0' && b[j] == '\0')
        return 1;
    return 0;
}

///Возвращает константу в 10-ной СС
u_int8_t getConst10D(const int op[]){
    u_int8_t value = 0;
    for(int i = 1; op[i] != '\0'; i++)
        value = value * 10 + op[i] - '0';
    return value;
}

///Возвращает константу в 16-ной СС
u_int8_t getConst16D(const int op[]){
    u_int8_t value = 0;
    for(int i = 1; op[i] != '\0'; i++)
        value = value * 16 + op[i] - (isdigit(op[i]) ? '0' : 'A' - 10);
    return value;
}

OpTypes getType(const int op[]){

}

/// Подфункция getOp \n
/// 1 - залезли на пробел/другой операнд \n
/// 0 - читаем дальше
char checkStopCharGetOp(int c){
    switch(c){
        case '{': case '}': case '[': case ']':
        case ',': case ' ': case '\t': case '\n':
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

    switch(c){
        case EOF:
            op[i++] = '\0';
            return i;
        case '{': case '}': case '[': case ']': case ',':
            op[i++] = c;
            op[i++] = '\0';
            return i;
        default:
            do{
                op[i++] = c;
                c = getc(input);
            }while(i < size && !checkStopCharGetOp(c));
            if(c == '\n')
                ungetc(c, input);
    }
}

typedef enum getFrameStates_{
    getFrameEnd = -1, ///< если конец достигнут
    getFrameOk = 0 ///< если конец не достигнут
} getFrameStates;

getFrameStates getControlFrame(FILE* input, Stack *output, unsigned int *ptrLineNum){

}

getFrameStates getInsnFrame(FILE* input, Stack *output, Defines *defs, unsigned int *ptrLineNum){
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}


//FIXME: считать фрейм и проверить, достигнут ли конец
getFrameStates getFrame(FILE *input, Stack *output, Defines *defs, unsigned int ptrLineNum){

    return OK;
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
        frameState = getFrame(input, output, &defs, lineNum);
        i++;
    } while(i < FRAMES_COUNT && frameState == OK);

    //FIXME: проверить labels и подставить

    return CompilerOK;
}

int printProgramFromStackToFile(Stack* input, FILE* output){

}

CompilerStates compileTextToText(FILE* input, FILE* output){ //FIXME
    CompilerStates state;
    Stack* ptrProgram = dStackInit(INSN_SIZE);
    state = compileFileToStack(input, ptrProgram);
    if(state == CompilerOK)
        printProgramFromStackToFile(ptrProgram, output);
    return state;
}