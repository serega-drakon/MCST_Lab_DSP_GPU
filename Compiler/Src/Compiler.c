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

#define EMPTY

#define MEM_CHECK(ptrMem,  errorCode, errorMsg, ...) \
do{ if(ptrMem == NULL){                              \
printf(errorMsg, __VA_ARGS__);                       \
     printf("\n");                                   \
return errorCode;} } while(0)

#define ERROR_MSG_NL(errorCode, errorMsg, ...) \
do { printf(errorMsg, __VA_ARGS__);            \
     printf("\n");                             \
     return errorCode; } while(0)

#define ERROR_MSG(ptrLineNum, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum));                   \
     printf(errorMsg, __VA_ARGS__);                  \
     printf("\n");                                   \
     return errorCode; } while(0)

#define ERROR_MSG_LEX(ptrLineNum, ptrLex, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum));                          \
     printf(errorMsg, __VA_ARGS__);                          \
     printf("\n -> ");                                      \
     for (int index = 0; (ptrLex)->op[index] != '\0'; index++)\
         printf("%c", (ptrLex)->op[index]);                   \
     printf("\n");    \
     return errorCode; } while(0)

#define WARNING(ptrLineNum, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum));     \
     printf(errorMsg __VA_ARGS__);                  \
     printf("\n"); } while(0)

///Конструктор
DefinesInitStates definesInit(Defines *defs){
    const char errorMsg[] = "defines memory allock error";
    defs->ptrLabelDefinedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelDefinedNames, errorMsg, DefinesInitError);
    defs->ptrLabelDefinedValues = dStackInit(sizeof(char));
    MEM_CHECK(defs->ptrLabelDefinedValues, errorMsg, DefinesInitError);
    defs->ptrLabelUsedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelUsedNames, errorMsg, DefinesInitError);
    defs->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(defs->ptrLabelUsedValuesPtr, errorMsg, DefinesInitError);
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

LexInitStates lexInit(lexeme *ptrLex){ //fixme
    assert(MAX_OP > 0);
    ptrLex->op = malloc(MAX_OP * sizeof(int));
    MEM_CHECK(ptrLex->op, "Error: lex mem alloc error", LexInitError);
    ptrLex->unGetStatus = UnGetLexFalse;
    ptrLex->lexType = Nothing;
    return LexInitSuccess;
}

void lexFree(lexeme *ptrLex){
    if(ptrLex != NULL){
        free(ptrLex->op);
    }
}

FrameDataInitStates frameDataInit(FrameData *ptrFrameData){
    char errorMsg[] = "Error: frameData mem alloc error";
    ptrFrameData->IF_Num_left = 0;
    ptrFrameData->CoreActiveVector = malloc(CORES_COUNT * sizeof(char));
    MEM_CHECK(ptrFrameData->CoreActiveVector, errorMsg, FrameDataInitError);
    ptrFrameData->InitR0Vector = malloc(CORES_COUNT * sizeof(char));
    MEM_CHECK(ptrFrameData->InitR0Vector, errorMsg, FrameDataInitError);
    return FrameDataInitSuccess;
}

void frameDataFree(FrameData *ptrFrameData){
    if(ptrFrameData != NULL){
        free(ptrFrameData->CoreActiveVector);
        free(ptrFrameData->InitR0Vector);
    }
}

void allFree(Defines *ptrDefs, lexeme *ptrLex, FrameData *ptrFrameData){
    definesFree(ptrDefs);
    lexFree(ptrLex);
    frameDataFree(ptrFrameData);
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

LexemeTypes translateOpCodeFromStrToLex(OpCodes_str_enum strEnum){
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

LexemeTypes translateCFParamNamesFromStrToLex(CFParamNames_str_enum strEnum){
    switch(strEnum){
            case InitR0_str: return InitR0;
            case CoreActive_str: return CoreActive;
            case Fence_str: return Fence;
            case IFNum_str: return IFNum;
        default: assert(0);
    }
}

LexemeTypes translateFenceModesFromStrToLex(FenceModes_str_enum strEnum){
    switch(strEnum){
            case FenceNo_str: return FenceNo;
            case FenceAcq_str: return FenceAcq;
            case FenceRel_str: return FenceRel;
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
            return translateRegFromStrToLex(i);
    }
    return Error;
}

LexemeTypes checkOthers(const int op[]){
    for(OpCodes_str_enum i = OpCodes_str_enum_MIN; i < OpCodes_str_enum_MAX; i++){
        if(compareStrIntChar(op, OpCodes_str_[i]))
            return translateOpCodeFromStrToLex(i);
    }
    for(CFParamNames_str_enum i = CFParamNames_str_enum_MIN; i < CFParamNames_str_enum_MAX; i++){
        if(compareStrIntChar(op, CFParamNames_str_[i]))
            return translateCFParamNamesFromStrToLex(i);
    }
    for(FenceModes_str_enum i = FenceModes_str_enum_MIN; i < FenceModes_str_enum_MAX; i++){
        if(compareStrIntChar(op, FenceModes_str_[i]))
            return translateFenceModesFromStrToLex(i);
    }
    return Name;
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
        case ':': return Colon;
        case '\0': return Nothing;
        default: return checkOthers(op);
    }
}

/// Подфункция getOp \n
/// 1 - залезли на 1char-symbol \n
/// 0 - не залезли
char checkOneCharOp(int c){
    switch(c){
        case '{': case '}': case '[': case ']':
        case ',': case '=': case '/': case ':':
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

    if(c != EOF){
        op[i++] = c;
        if(!checkOneCharOp(c)){
            while (i < (size - 1) && (c = getc(input)) != ' ' && c != '\n'
            && c != '\t' && !checkOneCharOp(c) && c != EOF) {
                op[i++] = c;
            }
            if(checkOneCharOp(c) || c == '\n' || c == EOF)
                ungetc(c, input);
        }
    }
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

void skipComments(FILE* input, lexeme *ptrLex, unsigned *ptrLineNum){
    int c;
    char commentEnd = 0;
    do{
        getLex(input, ptrLineNum, ptrLex);
        if(ptrLex->lexType == Slash){
            c = getc(input);
            if(c == '/') {
                while ((c = getc(input)) != '\n' || c != EOF)
                    ;
                ungetc(c, input);
            }
            else{
                unGetLex(ptrLex);
                commentEnd = 1;
            }
        }
    } while(!commentEnd);
}

GetFrameStates getControlFrame(FILE* input, Stack *output, FrameData *ptrFrameData, lexeme *ptrLex,
                               unsigned *ptrLineNum){

}

GetFrameStates getInsnFrame(FILE* input, Stack *output, Defines *ptrDefs, lexeme *ptrLex,
                            unsigned *ptrLineNum){
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}


//FIXME: считать фрейм и проверить, достигнут ли конец
GetFrameStates getFrame(FILE *input, Stack *output, Defines *ptrDefs, FrameData *ptrFrameData,
                        lexeme *ptrLex, unsigned *ptrLineNum){
    GetFrameStates frameState;
    skipComments(input, ptrLex, ptrLineNum);
    getLex(input, ptrLineNum, ptrLex);
    switch(ptrLex->lexType){
        case BracketCurlyOpen:
            if(ptrFrameData->IF_Num_left > 0)
                WARNING(*ptrLineNum, "Warning: There are IF left - %d", ptrFrameData->IF_Num_left);
            frameState = getControlFrame(input, output, ptrFrameData, ptrLex, ptrLineNum);
            //FIXME: проверка на frameData
            return frameState;
        case Colon:
            skipComments(input, ptrLex, ptrLineNum);
            getLex(input, ptrLineNum, ptrLex);
            if(ptrLex->lexType == Name){
                //FIXME
            }
            else
                unGetLex(ptrLex);
            frameState = getInsnFrame(input, output, ptrDefs, ptrLex, ptrLineNum);
            //FIXME: проверка на frameData
            return frameState;
        default:
            ERROR_MSG_LEX("Чо это такое, где символ начала фрейма?", GetFrameCodeError, ptrLex, *ptrLineNum);
    }
}

CheckEndStates checkEnd(FILE *input, lexeme *ptrLex, unsigned *ptrLineNum){
    //skipComments(input, ptrLex, )
}

CompilerStates compileFileToStack(FILE* input, Stack* output){
    MEM_CHECK(input, "Error: input file is NULL", CompilerErrorNullInput);
    MEM_CHECK(output, "Error: output stack is NULL", CompilerErrorNullStack);
    Defines defs;
    FrameData frameData;
    lexeme lex;
    if(definesInit(&defs) == DefinesInitError
    || lexInit(&lex) == LexInitError
    || frameDataInit(&frameData) == FrameDataInitError)
        goto memAllocError;
    GetFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;

    do {
        frameState = getFrame(input, output, &defs,
                              &frameData, &lex, &lineNum);
        i++;
    } while(i < FRAMES_COUNT && frameState == GetFrameOk);

    if(i == FRAMES_COUNT && frameState == GetFrameOk && checkEnd(input, &lex, &lineNum) == CheckEndNotReached) {
        allFree(&defs, &lex, &frameData);
        ERROR_MSG_LEX(&lineNum, &lex, CompilerErrorOverflowFrames,
                      "Warning: Out of range, max count of frames has reached - %d", FRAMES_COUNT);
    }

    allFree(&defs, &lex, &frameData);
    switch(frameState){
    case GetFrameOk: case GetFrameEnd:
        return CompilerOK;
    case GetFrameCodeError:
        return CompilerErrorUserCode;
    default:
        assert(0);
    }

    memAllocError: //FIXME: pomenat
    allFree(&defs, &lex, &frameData);
    printf("Error: mem alloc error\n");
    return CompilerErrorMemAlloc;
}

void printProgramFromStackToFile(Stack* input, FILE* output){

}

void printCompilerState(CompilerStates state){
    switch(state){
        default://FIXME
            return;
    }
}

CompilerStates compileTextToText(FILE* input, FILE* output){ //FIXME
    CompilerStates state;
    Stack* ptrProgram = dStackInit(INSN_SIZE);
    state = compileFileToStack(input, ptrProgram);
    printCompilerState(state);
    if(state == CompilerOK)
        printProgramFromStackToFile(ptrProgram, output);
    dStackFree(ptrProgram);
    return state;
}