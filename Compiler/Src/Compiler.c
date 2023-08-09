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
#include "Enums&Structs.h"

#define MEM_CHECK(ptrMem, errorName, errorCode) \
do{ if(ptrMem == NULL){printf(errorName); return errorCode;} } while(0)

#define ERROR_MSG_NL(errorMsg, errorCode) \
do { printf("%s%s", errorMsg, "\n");  \
return errorCode; } while(0)

#define ERROR_MSG(errorMsg, errorCode, lineNum) \
do { printf("Line %d: %s%s", lineNum, errorMsg, "\n");  \
return errorCode; } while(0)

#define ERROR_MSG_LEX(errorMsg, errorCode, ptrLex, lineNum) \
do { printf("Line %d: %s%s", lineNum, errorMsg, "\n -> ");  \
for (int index = 0; ptrLex->op[index] != '\0'; index++) \
    printf("%c", ptrLex->op[index]);                    \
printf("\n");                                   \
return errorCode; } while(0)

///Конструктор
DefinesInitStates definesInit(Defines *defs){
    const char error_msg[] = "defines memory allock error";
    defs->ptrLabelDefinedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelDefinedNames, error_msg, DefinesInitError);
    defs->ptrLabelDefinedValues = dStackInit(sizeof(char));
    MEM_CHECK(defs->ptrLabelDefinedValues, error_msg, DefinesInitError);
    defs->ptrLabelUsedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelUsedNames, error_msg, DefinesInitError);
    defs->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(defs->ptrLabelUsedValuesPtr, error_msg, DefinesInitError);
    return DefinesInitOK;
}

///Деструктор
void definesFree(struct Defines_ *ptrDef){
    if(ptrDef != NULL) {
        dStackFree(ptrDef->ptrLabelDefinedNames);
        dStackFree(ptrDef->ptrLabelDefinedValues);
        dStackFree(ptrDef->ptrLabelUsedNames);
        if(ptrDef->ptrLabelUsedValuesPtr != NULL) {
            const u_int32_t size = getsize_dStack(ptrDef->ptrLabelUsedValuesPtr);
            for (int i = 0; i < size; i++)
                dStackFree(*(void **) dStack_r(ptrDef->ptrLabelUsedValuesPtr, i));
            dStackFree(ptrDef->ptrLabelUsedValuesPtr);
        }
    }
}

lexeme *lexInit(){
    assert(MAX_OP > 0);
    lexeme *ptrLex = malloc(sizeof(lexeme));
    if(ptrLex != NULL) {
        ptrLex->op[0] = '\0';
        ptrLex->unGetStatus = UnGetLexFalse;
        ptrLex->lexType = Nothing;
    }
}

void lexFree(lexeme *ptrLex){
    free(ptrLex);
}

LexemeTypes translateRegFromStrToLex(Registers_str_enum strEnum){
    switch(strEnum){
        case Reg_R0_str: return Reg_R0;
        case Reg_R1_str: return Reg_R1;
        case Reg_R2_str: return Reg_R2;
        case Reg_R3_str: return Reg_R3;
        case Reg_R4_str: return Reg_R4;
        case Reg_R5_str: return Reg_R5;
        case Reg_R6_str: return Reg_R6;
        case Reg_R7_str: return Reg_R7;
        case Reg_R8_str: return Reg_R8;
        case Reg_R9_str: return Reg_R9;
        case Reg_R10_str: return Reg_R10;
        case Reg_R11_str: return Reg_R11;
        case Reg_R12_str: return Reg_R12;
        case Reg_R13_str: return Reg_R13;
        case Reg_R14_str: return Reg_R14;
        case Reg_R15_str: return Reg_R15;
        default: assert(0);
    }
}

LexemeTypes translateOpCodeFromStrToLex(Registers_str_enum strEnum){
    switch(strEnum){
        case Nop_str: return Nop;
        case Add_str: return Add;
        case Sub_str: return Sub;
        case Mul_str: return Mul;
        case Div_str: return Div;
        case Cmpge_str: return Cmpge;
        case Rshift_str: return Rshift;
        case Lshift_str: return Lshift;
        case And_str: return And;
        case Or_str: return Or;
        case Xor_str: return Xor;
        case Ld_str: return Ld;
        case Set_const_str: return Set_const;
        case St_str: return St;
        case Bnz_str: return Bnz;
        case Ready_str: return Ready;
        default: assert(0);
    }
}

///Подфункция getType
LexemeTypes checkConst16(const int op[]){
    if(op[1] == '\0')
        return Error;
    for (int i = 1; op[i] != '\0'; i++)
        if (!isdigit(op[i]) && (op[i] < 'A' || op[i] > 'F')) return Error;
    return Const16;
}

///Подфункция getType
LexemeTypes checkConst10(const int op[]){
    if(op[1] == '\0')
        return Error;
    for(int i = 1; op[i] != '\0'; i++)
        if(!isdigit(op[i])) return Error;
    return Const10;
}

///Подфункция getType
LexemeTypes checkReg(const int op[]){
    for(Registers_str_enum i = Registers_str_enum_MIN; i < Registers_str_enum_MAX; i++){
        if(compareStrIntChar(&op[1], Registers_str_[i]))
            return translateRegFromStrToLex(i); //FIXME
    }
    return Error;
}

LexemeTypes checkOthers(const int op[]){
    //FIXME
}

LexemeTypes getType(const int op[]){
    switch(op[0]){
        case '$': return checkConst16(op);
        case '!': return checkConst10(op);
        case '%': return checkReg(op);
        case '.': return Label;
        case '{': return BracketCurlyOpen;
        case '}': return BracketCurlyClose;
        case '[': return BracketSquareOpen;
        case ']': return BracketSquareClose;
        case ',': return Comma;
        case '=': return Equal;
        case '/': return Slash;
        case '\0': return Nothing;
        default: return checkOthers(op);
    }
}

/// Подфункция getOp \n
/// 1 - залезли на 1char-symbol \n
/// 0 - не залезли
char checkStopCharGetOp(int c){
    switch(c){
        case '{': case '}': case '[': case ']':
        case ',': case '=': case '/':
            return 1;
        default:
            return 0;
    }
}

/// Получает операнд из потока ввода \n
/// Возвращает длину полученной строки
int getOp(FILE* input, unsigned *ptrLineNum, int op[], unsigned int size){
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

void getLex(FILE *input, unsigned *ptrLineNum, lexeme *ptrLex){
    if(ptrLex->unGetStatus == UnGetLexTrue){
        ptrLex->unGetStatus = UnGetLexFalse;
        return;
    }
    else {
        getOp(input, ptrLineNum, ptrLex->op, MAX_OP);
        ptrLex->lexType = getType(ptrLex->op);
        return;
    }
}

void unGetLex(lexeme *ptrLex){
    assert(ptrLex != NULL && ptrLex->unGetStatus == UnGetLexFalse);
    ptrLex->unGetStatus = UnGetLexTrue;
}

SkipCommentsState skipComments(FILE* input, lexeme *ptrLex){

}

getFrameStates getControlFrame(FILE* input, Stack *output, lexeme *ptrLex, unsigned int *ptrLineNum){

}

getFrameStates getInsnFrame(FILE* input, Stack *output, Defines *defs, lexeme *ptrLex, unsigned int *ptrLineNum){
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}


//FIXME: считать фрейм и проверить, достигнут ли конец
getFrameStates getFrame(FILE *input, Stack *output, Defines *defs, lexeme *ptrLex, unsigned int *ptrLineNum){

    return GetFrameOk;
}

CheckEndStates checkEnd(FILE *input, lexeme *ptrLex){

}

CompilerStates compileFileToStack(FILE* input, Stack* output){
    MEM_CHECK(input, "Error: input file is NULL", CompilerErrorNullInput);
    MEM_CHECK(output, "Error: output stack is NULL", CompilerErrorNullStack);
    Defines defs;
    if(definesInit(&defs) == DefinesInitError){
        definesFree(&defs);
        return CompilerErrorMemAlloc;
    }
    getFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;
    lexeme *ptrLex = lexInit();
    MEM_CHECK(ptrLex, "Error: ptrLex mem alloc error", CompilerErrorMemAlloc);
    do {
        frameState = getFrame(input, output, &defs, ptrLex, &lineNum);
        i++;
    } while(i < FRAMES_COUNT && frameState == GetFrameOk);
    definesFree(&defs);
    if(i == FRAMES_COUNT && frameState == GetFrameOk) {
        if(checkEnd(input, ptrLex)) {
            lexFree(ptrLex);
            ERROR_MSG_LEX("Error: Out of range, max count of frames has reached",
                          CompilerErrorOverflowFrames, ptrLex, lineNum);
        }
    }
    lexFree(ptrLex);
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