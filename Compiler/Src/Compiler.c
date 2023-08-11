//
// Created by Сергей Слепышев on 04.08.2023.
// все претензии по коду к нему
// https://github.com/Zararest

#include <stdio.h>
#include <ctype.h>
#include <assert.h>
#include <string.h>
#include "Compiler.h"
#include "dStack.h"
#include "strings.h"
#include "encodings.h"
#include "UsefulFuncs.h"
#include "Enums&Structs.h"

#define MEM_CHECK(ptrMem,  errorCode, errorMsg, ...) \
do{ if(ptrMem == NULL){                              \
        printf(errorMsg __VA_ARGS__);               \
        printf("\n");                                \
        return errorCode;} } while(0)

#define ERROR_MSG_NL(errorCode, errorMsg, ...) \
do { printf(errorMsg __VA_ARGS__);            \
     printf("\n");                             \
     return errorCode; } while(0)

#define ERROR_MSG(ptrLineNum, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum));                \
     printf(errorMsg __VA_ARGS__);                     \
     printf("\n");                                      \
     return errorCode; } while(0)

#define ERROR_MSG_LEX(ptrLineNum, ptrLex, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum));                            \
     printf(errorMsg __VA_ARGS__);                                 \
     printf("\n -> %ls\n", (ptrLex)->op);                           \
     return errorCode; } while(0)

#define WARNING(ptrLineNum, errorMsg, ...)  \
do { printf("Line %d: ", *(ptrLineNum));    \
     printf(errorMsg __VA_ARGS__);          \
     printf("\n"); } while(0)

DefinesInitStates definesInit(Defines *defs){
    const char errorMsg[] = "Defines memory alloc error";
    defs->ptrLabelDefinedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelDefinedNames, DefinesInitError, errorMsg);
    defs->ptrLabelDefinedValues = dStackInit(sizeof(char));
    MEM_CHECK(defs->ptrLabelDefinedValues, DefinesInitError, errorMsg);
    defs->ptrLabelUsedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelUsedNames, DefinesInitError, errorMsg);
    defs->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(defs->ptrLabelUsedValuesPtr, DefinesInitError, errorMsg);
    return DefinesInitOK;
}

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
    MEM_CHECK(ptrLex->op, LexInitError, "Error: lex mem alloc error");
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
    const char errorMsg[] = "Error: frameData mem alloc error";
    ptrFrameData->IF_Num_left = 0;
    ptrFrameData->fenceMode = FenceNo_mode;
    ptrFrameData->coreActiveVector = calloc(CORES_COUNT, sizeof(VectorStates));
    MEM_CHECK(ptrFrameData->coreActiveVector, FrameDataInitError, errorMsg);
    ptrFrameData->initR0Vector = calloc(CORES_COUNT, sizeof(VectorStates));
    MEM_CHECK(ptrFrameData->initR0Vector, FrameDataInitError, errorMsg);
    ptrFrameData->initR0data = calloc(CORES_COUNT, REG_SIZE);
    MEM_CHECK(ptrFrameData->initR0data, FrameDataInitError, errorMsg);
    return FrameDataInitSuccess;
}

void frameDataReset(FrameData *ptrFrameData){
    ptrFrameData->IF_Num_left = 0;
    ptrFrameData->fenceMode = FenceNo_mode;
    putZeroes(ptrFrameData->coreActiveVector, CORES_COUNT * sizeof(VectorStates));
    putZeroes(ptrFrameData->initR0Vector, CORES_COUNT * sizeof(VectorStates));
    putZeroes(ptrFrameData->initR0data, CORES_COUNT * REG_SIZE);
}

void frameDataFree(FrameData *ptrFrameData){
    if(ptrFrameData != NULL){
        free(ptrFrameData->coreActiveVector);
        free(ptrFrameData->initR0Vector);
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

///Подфункция getType
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

void skipComments(FILE *input, unsigned *ptrLineNum, lexeme *ptrLex) {
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

ProcessStates processInitR0(FILE* input, FrameData *ptrFrameData, lexeme *ptrLex, unsigned *ptrLineNum){

}

ProcessStates processCoreActive(FILE* input, FrameData *ptrFrameData, lexeme *ptrLex, unsigned *ptrLineNum){

}

ProcessStates processFence(FILE* input, FrameData *ptrFrameData, lexeme *ptrLex, unsigned *ptrLineNum){

}

ProcessStates processIFNum(FILE* input, FrameData *ptrFrameData, lexeme *ptrLex, unsigned *ptrLineNum){

}

void pushCFtoStack(Stack *output, FrameData *frameData){

}

GetFrameStates getControlFrame(FILE* input, Stack *output, FrameData *ptrFrameData, lexeme *ptrLex,
                               unsigned *ptrLineNum){
    frameDataReset(ptrFrameData);
    do{
        skipComments(input, ptrLineNum, ptrLex);
        getLex(input, ptrLineNum, ptrLex);
        switch(ptrLex->lexType){
            case InitR0:
                if(processInitR0(input, ptrFrameData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: InitR0 error");
                break;
            case CoreActive:
                if(processCoreActive(input, ptrFrameData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: CoreActive error");
                break;
            case Fence:
                if(processFence(input, ptrFrameData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Fence error");
                break;
            case IFNum:
                if(processIFNum(input, ptrFrameData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: IFNum error");
                break;
            case BracketCurlyClose:
                break;
            case Nothing:
                ERROR_MSG(ptrLineNum, GetFrameCodeError, "Ожидался \"}\", а получен конец файла... ну и кринжовый ты тип....");
            default:
                ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое в CF?");
        }
    } while(ptrLex->lexType == BracketCurlyClose);
    pushCFtoStack(output, ptrFrameData);
    return GetFrameOk;
}

ProcessStates processInsnWithNoArgs(){

}

ProcessStates processInsnWithTwoRegs(){

}

ProcessStates processInsnWithRegAndConst(){

}

ProcessStates processInsnWithLabel(){

}

ProcessStates processLabelDefinition(){

}

ProcessStates processCheckLabels(){

}

void processPutLabels(){

}

void pushIFtoStack(Stack *output){

}

GetFrameStates getInsnFrame(FILE* input, Stack *output, Defines *ptrDefs, lexeme *ptrLex,
                            unsigned *ptrLineNum){
    unsigned insnNum = 0;
    do{
        skipComments(input, ptrLineNum, ptrLex);
        getLex(input, ptrLineNum, ptrLex);
        switch (ptrLex->lexType) { // оп оп грамматика пошла
            case Nop: case Ready:
                if(processInsnWithNoArgs() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with no args error");
                break;
            case Add: case Sub: case Mul: case Div: case Cmpge: case Rshift:
            case Lshift: case And: case Or: case Xor: case Ld:  case St:
                if(processInsnWithTwoRegs() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with two regs error");
                break;
            case Set_const:
                if(processInsnWithRegAndConst() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with reg and Const error");
                break;
            case Bnz:
                if(processInsnWithLabel() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with reg and Const error");
                break;
            case Label:
                if(processLabelDefinition() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Label definition error");
                break;
            case Colon: case BracketCurlyOpen: case Nothing:
                unGetLex(ptrLex);
                break;
            default:
                ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое в IF?");
        }
    } while(insnNum < INSN_COUNT
    && ptrLex->lexType != Nothing && ptrLex->lexType != Colon && ptrLex->lexType != BracketCurlyOpen);
    if(processCheckLabels() == ProcessError)
        ;
    processPutLabels();
    pushIFtoStack(output);
    return GetFrameOk;

    //все лейблы прочитать не забыть!
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}

CheckCFFlags checkCFFlags(FrameData *ptrFrameData){
    assert(ptrFrameData != NULL && ptrFrameData->initR0Vector != NULL && ptrFrameData->coreActiveVector != NULL);
    for(unsigned i = 0; i < CORES_COUNT; i++){
        if(ptrFrameData->initR0Vector[i] == VectorActive
        && ptrFrameData->coreActiveVector[i] == VectorNoActive)
            return CheckCFFlagsWarning;
    }
    return CheckCFFlagsSuccess;
}

GetFrameStates processControlFrame(FILE* input, Stack *output, FrameData *ptrFrameData, lexeme *ptrLex,
                                   unsigned *ptrLineNum){
    if(ptrFrameData->IF_Num_left > 0)
        WARNING(ptrLineNum, "Warning: There are IFs left - %d",, ptrFrameData->IF_Num_left);
    GetFrameStates frameState = getControlFrame(input, output, ptrFrameData, ptrLex, ptrLineNum);
    if(checkCFFlags(ptrFrameData) == CheckCFFlagsWarning)
        WARNING(ptrLineNum, "Warning: InitR0 > CoreActive???");
    return frameState;
}

GetFrameStates processInsnFrame(FILE* input, Stack *output, Defines *ptrDefs, FrameData *ptrFrameData,
                                lexeme *ptrLex, unsigned *ptrLineNum){
    skipComments(input, ptrLineNum, ptrLex);
    getLex(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Name)
        unGetLex(ptrLex);
    if(ptrFrameData->IF_Num_left > 0){
        ptrFrameData->IF_Num_left--;
    }
    else {
        if(ptrLex->lexType == Name)
            WARNING(ptrLineNum, "Warning: There are CF needed before \"%ls%s",, ptrLex->op, "\"");
        else
            WARNING(ptrLineNum, "Warning: There are CF needed before");
    }
    GetFrameStates frameState = getInsnFrame(input, output, ptrDefs, ptrLex, ptrLineNum);
    return frameState;
}

GetFrameStates getFrame(FILE *input, Stack *output, Defines *ptrDefs, FrameData *ptrFrameData,
                        lexeme *ptrLex, unsigned *ptrLineNum){
    skipComments(input, ptrLineNum, ptrLex);
    getLex(input, ptrLineNum, ptrLex);
    switch(ptrLex->lexType){
        case BracketCurlyOpen:
            return processControlFrame(input, output, ptrFrameData, ptrLex, ptrLineNum);
        case Colon:
            return processInsnFrame(input, output, ptrDefs, ptrFrameData, ptrLex, ptrLineNum);
        case Nothing:
            return GetFrameEnd;
        default:
            ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое, где символ начала фрейма?");
    }
}

CheckEndStates checkEnd(FILE *input, lexeme *ptrLex, unsigned *ptrLineNum){
    skipComments(input, ptrLineNum, ptrLex);
    getLex(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType == Nothing)
        return CheckEndReached;
    else
        return CheckEndNotReached;
}

CompilerStates compileFileToStack(FILE* input, Stack* output){
    MEM_CHECK(input, CompilerErrorNullInput, "Error: input file is NULL");
    MEM_CHECK(output, CompilerErrorNullStack, "Error: output stack is NULL");
    Defines defs;
    FrameData frameData;
    lexeme lex;
    if(definesInit(&defs) == DefinesInitError
    || lexInit(&lex) == LexInitError
    || frameDataInit(&frameData) == FrameDataInitError){
        allFree(&defs, &lex, &frameData);
        ERROR_MSG_NL(CompilerErrorMemAlloc, "Error: mem alloc error");
    }
    GetFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;

    do {
        frameState = getFrame(input, output, &defs,
                  &frameData, &lex, &lineNum);
    } while(++i < FRAMES_COUNT && frameState == GetFrameOk);

    if(i == FRAMES_COUNT && frameState == GetFrameOk
    && checkEnd(input, &lex, &lineNum) == CheckEndNotReached) {
        allFree(&defs, &lex, &frameData);
        ERROR_MSG_LEX(&lineNum, &lex, CompilerErrorOverflowFrames,
                      "Warning: Out of range, max count of frames has reached - %d",, FRAMES_COUNT);
    }

    //todo: warning frame count

    allFree(&defs, &lex, &frameData);
    switch(frameState){
    case GetFrameOk: case GetFrameEnd:
        return CompilerOK;
    case GetFrameCodeError:
        return CompilerErrorUserCode;
    default:
        assert(0);
    }
}

void printCompilerState(CompilerStates state){
    switch(state){
        default://todo
            return;
    }
}

void printProgramFromStackToFile(Stack* input, FILE* output){
    //todo
}

CompilerStates compileTextToText(FILE* input, FILE* output){
    CompilerStates state;
    Stack* ptrProgram = dStackInit(INSN_SIZE);
    state = compileFileToStack(input, ptrProgram);
    printCompilerState(state);
    if(state == CompilerOK || state == CompilerErrorOverflowFrames)
        printProgramFromStackToFile(ptrProgram, output);
    dStackFree(ptrProgram);
    return state;
}

void printProgramFromStackToBin(Stack* input, FILE* output){
    //todo
}

CompilerStates compileTextToBin(FILE *input, FILE *output){
    CompilerStates state;
    Stack* ptrProgram = dStackInit(INSN_SIZE);
    state = compileFileToStack(input, ptrProgram);
    printCompilerState(state);
    if(state == CompilerOK || state == CompilerErrorOverflowFrames)
        printProgramFromStackToBin(ptrProgram, output);
    dStackFree(ptrProgram);
    return state;
}