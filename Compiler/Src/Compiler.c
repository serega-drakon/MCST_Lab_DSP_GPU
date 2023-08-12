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

#define MEM_CHECK(ptrMem, errorCode, errorMsg, ...)  \
do{ if(ptrMem == NULL){                              \
        printf(errorMsg __VA_ARGS__);                \
        printf("\n");                                \
        return errorCode;} } while(0)

#define ERROR_MSG_NL(errorCode, errorMsg, ...) \
do { printf(errorMsg __VA_ARGS__);             \
     printf("\n");                             \
     return errorCode; } while(0)

#define ERROR_MSG(ptrLineNum, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum) + 1);            \
     printf(errorMsg __VA_ARGS__);                      \
     printf("\n");                                      \
     return errorCode; } while(0)

#define ERROR_MSG_LEX(ptrLineNum, ptrLex, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum) + 1);                        \
     printf(errorMsg __VA_ARGS__);                                  \
     printf("\n -> %ls\n", (ptrLex)->op);                           \
     return errorCode; } while(0)

#define WARNING(ptrLineNum, errorMsg, ...)      \
do { printf("Line %d: ", *(ptrLineNum) + 1);    \
     printf(errorMsg __VA_ARGS__);              \
     printf("\n"); } while(0)

#define WARNING_LEX(ptrLineNum, ptrLex, errorMsg, ...)  \
do { printf("Line %d: ", *(ptrLineNum) + 1);            \
     printf(errorMsg __VA_ARGS__);                      \
     printf("\n -> %ls\n", (ptrLex)->op);               \
     printf("\n"); } while(0)

InitStates definesInit(Defines *defs){
    const char errorMsg[] = "Defines memory alloc error";
    defs->ptrLabelDefinedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelDefinedNames, InitError, errorMsg);
    defs->ptrLabelDefinedValues = dStackInit(sizeof(char));
    MEM_CHECK(defs->ptrLabelDefinedValues, InitError, errorMsg);
    defs->ptrLabelUsedNames = dStackInit(sizeof(int));
    MEM_CHECK(defs->ptrLabelUsedNames, InitError, errorMsg);
    defs->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(defs->ptrLabelUsedValuesPtr, InitError, errorMsg);
    return InitOK;
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

InitStates lexInit(lexeme *ptrLex){
    assert(MAX_OP > 0);
    ptrLex->op = malloc(MAX_OP * sizeof(int));
    MEM_CHECK(ptrLex->op, InitError, "Error: lex mem alloc error");
    ptrLex->unGetStatus = UnGetLexFalse;
    ptrLex->lexType = Nothing;
    return InitOK;
}

void lexFree(lexeme *ptrLex){
    if(ptrLex != NULL){
        free(ptrLex->op);
    }
}

InitStates controlFrameDataInit(ControlFrameData *ptrCFData){
    const char errorMsg[] = "Error: controlFrameData mem alloc error";
    ptrCFData->IF_Num_left = 0;
    ptrCFData->fenceMode = FenceNo_mode;
    ptrCFData->coreActiveVector = calloc(CORES_COUNT, sizeof(VectorStates));
    MEM_CHECK(ptrCFData->coreActiveVector, InitError, errorMsg);
    ptrCFData->initR0Vector = calloc(CORES_COUNT, sizeof(VectorStates));
    MEM_CHECK(ptrCFData->initR0Vector, InitError, errorMsg);
    ptrCFData->initR0data = calloc(CORES_COUNT, REG_SIZE);
    MEM_CHECK(ptrCFData->initR0data, InitError, errorMsg);
    return InitOK;
}

void controlFrameDataReset(ControlFrameData *ptrCFData){
    ptrCFData->IF_Num_left = 0;
    ptrCFData->fenceMode = FenceNo_mode;
    putZeroes(ptrCFData->coreActiveVector, CORES_COUNT * sizeof(VectorStates));
    putZeroes(ptrCFData->initR0Vector, CORES_COUNT * sizeof(VectorStates));
    putZeroes(ptrCFData->initR0data, CORES_COUNT * REG_SIZE);
}

void controlFrameDataFree(ControlFrameData *ptrCFData){
    if(ptrCFData != NULL){
        free(ptrCFData->coreActiveVector);
        free(ptrCFData->initR0Vector);
    }
}

InitStates insnFrameDataInit(InsnFrameData *ptrIFData){
    ptrIFData->ptrInsn = calloc(INSN_COUNT, sizeof(insnData));
    MEM_CHECK(ptrIFData->ptrInsn, InitError, "Error: insnFrameData mem alloc error");
    return InitOK;
}

void insnReset(insnData *ptrInsn){
    assert(ptrInsn != NULL);
    ptrInsn->opCode = Nop_insn;
    ptrInsn->src0 = Reg_R0_insn;
    ptrInsn->src1 = Reg_R0_insn;
    ptrInsn->src2dst = Reg_R0_insn;
    ptrInsn->constData = 0;
    ptrInsn->target = 0;
}

void insnFrameDataReset(InsnFrameData *ptrIFData){
    for(unsigned i = 0; i < INSN_COUNT; i++)
        insnReset(&ptrIFData->ptrInsn[i]);
}

void insnFrameDataFree(InsnFrameData *ptrIFData){
    if(ptrIFData != NULL)
        free(ptrIFData->ptrInsn);
}

InitStates allInit(Defines *ptrDefs, lexeme *ptrLex, ControlFrameData *ptrCFData, InsnFrameData *ptrIFData){
    if(definesInit(ptrDefs) == InitError
       || lexInit(ptrLex) == InitError
       || controlFrameDataInit(ptrCFData) == InitError
       || insnFrameDataInit(ptrIFData) == InitError)
        return InitError;
    return InitOK;
}

void allFree(Defines *ptrDefs, lexeme *ptrLex, ControlFrameData *ptrCFData, InsnFrameData *ptrIFData){
    definesFree(ptrDefs);
    lexFree(ptrLex);
    controlFrameDataFree(ptrCFData);
    insnFrameDataFree(ptrIFData);
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
        case ';': return Semicolon;
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
        case ';':
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
                while ((c = getc(input)) != '\n' && c != EOF)
                    ;
                ungetc(c, input);
            }
            else{
                unGetLex(ptrLex);
                commentEnd = 1;
            }
        }
        else{
            unGetLex(ptrLex);
            commentEnd = 1;
        }
    } while(!commentEnd);
}

uint8_t isConst(lexeme *ptrLex){
    return (ptrLex->lexType == Const10 || ptrLex->lexType == Const16);
}

uint8_t getConst(lexeme *ptrLex){
    assert(ptrLex->lexType == Const10 || ptrLex->lexType == Const16);
    return (ptrLex->lexType == Const10) ? getConst10D(ptrLex->op) : getConst16D(ptrLex->op);
}

void getLexNoComments(FILE *input, unsigned *ptrLineNum, lexeme *ptrLex){
    skipComments(input, ptrLineNum, ptrLex);
    getLex(input, ptrLineNum, ptrLex);
}

ProcessStates processInitR0(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != BracketSquareOpen)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо открыть скобочку");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(!isConst(ptrLex))
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо число");
    uint8_t index = getConst(ptrLex);
    getLexNoComments(input, ptrLineNum, ptrLex);;
    if(ptrLex->lexType != BracketSquareClose)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо закрыть скобочку");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(!isConst(ptrLex))
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо значение");
    uint8_t data = getConst(ptrLex);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Semicolon)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут точку с запятой");
    ptrCFData->initR0data[index] = data;
    return ProcessOK;
}

ProcessStates processCoreActive(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    do {
        getLexNoComments(input, ptrLineNum, ptrLex);
        if (!isConst(ptrLex))
            ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо значение");
        uint8_t index = getConst(ptrLex);
        ptrCFData->coreActiveVector[index] = VectorActive;
        getLexNoComments(input, ptrLineNum, ptrLex);
        if (ptrLex->lexType != Comma && ptrLex->lexType != Semicolon)
            ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо запятую или точку с запятой");
    } while(ptrLex->lexType != Semicolon);
    return ProcessOK;
}

ProcessStates processFence(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    getLexNoComments(input, ptrLineNum, ptrLex);
    switch(ptrLex->lexType){
        case FenceNo:
            ptrCFData->fenceMode = FenceNo_mode;
            break;
        case FenceAcq:
            ptrCFData->fenceMode = FenceAcq_mode;
            break;
        case FenceRel:
            ptrCFData->fenceMode = FenceRel_mode;
            break;
        default:
            ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо режим Fence");
    }
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Semicolon)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут точку с запятой");
    return ProcessOK;
}

ProcessStates processIFNum(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(!isConst(ptrLex))
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо число");
    uint8_t count = getConst(ptrLex);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Semicolon)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут точку с запятой");
    ptrCFData->IF_Num_left = count;
    return ProcessOK;
}

GetFrameStates getControlFrame(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                               unsigned *ptrLineNum){
    controlFrameDataReset(ptrCFData);
    do{
        getLexNoComments(input, ptrLineNum, ptrLex);
        switch(ptrLex->lexType){
            case InitR0:
                if(processInitR0(input, ptrCFData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: InitR0 error");
                break;
            case CoreActive:
                if(processCoreActive(input, ptrCFData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: CoreActive error");
                break;
            case Fence:
                if(processFence(input, ptrCFData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Fence error");
                break;
            case IFNum:
                if(processIFNum(input, ptrCFData, ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: IFNum error");
                break;
            case BracketCurlyClose:
                break;
            case Nothing:
                ERROR_MSG(ptrLineNum, GetFrameCodeError, "Ожидался \"}\", а получен конец файла... ну и кринжовый ты тип....");
            default:
                ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое в CF?");
        }
    } while(ptrLex->lexType != BracketCurlyClose);
    return GetFrameOK;
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

GetFrameStates getInsnFrame(FILE *input, Defines *ptrDefs, InsnFrameData *ptrIFData,
                            lexeme *ptrLex, unsigned *ptrLineNum){
    insnFrameDataReset(ptrIFData);
    unsigned insnNum = 0;
    do{
        getLexNoComments(input, ptrLineNum, ptrLex);
        switch (ptrLex->lexType) { // оп оп грамматика пошла
            case Nop: case Ready:
                insnNum++;
                if(processInsnWithNoArgs() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with no args error");
                break;
            case Add: case Sub: case Mul: case Div: case Cmpge: case Rshift:
            case Lshift: case And: case Or: case Xor: case Ld:  case St:
                insnNum++;
                if(processInsnWithTwoRegs() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with two regs error");
                break;
            case Set_const:
                insnNum++;
                if(processInsnWithRegAndConst() == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with reg and Const error");
                break;
            case Bnz:
                insnNum++;
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
        ERROR_MSG_NL(GetFrameCodeError, "Чот тут метки не сходятся");
    processPutLabels();
    return GetFrameOK;

    //все лейблы прочитать не забыть!
    //FIXME: заполнить defs, использовать и сбросить
    //FIXME: подсчет команд внутри фрейма
}

CheckCFFlags checkCFFlags(ControlFrameData *ptrCFData){
    assert(ptrCFData != NULL && ptrCFData->initR0Vector != NULL && ptrCFData->coreActiveVector != NULL);
    for(unsigned i = 0; i < CORES_COUNT; i++){
        if(ptrCFData->initR0Vector[i] == VectorActive
        && ptrCFData->coreActiveVector[i] == VectorNoActive)
            return CheckCFFlagsWarning;
    }
    return CheckCFFlagsSuccess;
}

void pushCFtoStack(Stack *output, ControlFrameData *ptrCFData){
    //todo
}

GetFrameStates processControlFrame(FILE* input, Stack *output, ControlFrameData *ptrCFData, lexeme *ptrLex,
                                   unsigned *ptrLineNum){
    if(ptrCFData->IF_Num_left > 0)
        WARNING(ptrLineNum, "Warning: There are IFs left - %d",, ptrCFData->IF_Num_left);
    GetFrameStates frameState = getControlFrame(input, ptrCFData, ptrLex, ptrLineNum);
    if(checkCFFlags(ptrCFData) == CheckCFFlagsWarning)
        WARNING(ptrLineNum, "Warning: InitR0 > CoreActive???");
    pushCFtoStack(output, ptrCFData);
    return frameState;
}

void pushIFtoStack(Stack *output, InsnFrameData *ptrIFData){
    //todo
}

GetFrameStates processInsnFrame(FILE* input, Stack *output, Defines *ptrDefs, ControlFrameData *ptrCFData,
                                InsnFrameData *ptrIFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Name)
        unGetLex(ptrLex);
    if(ptrCFData->IF_Num_left > 0){
        ptrCFData->IF_Num_left--;
    }
    else {
        if(ptrLex->lexType == Name)
            WARNING(ptrLineNum, "Warning: There are CF needed before \"%ls%s",, ptrLex->op, "\"");
        else
            WARNING(ptrLineNum, "Warning: There are CF needed before");
    }
    GetFrameStates frameState = getInsnFrame(input, ptrDefs, ptrIFData, ptrLex, ptrLineNum);
    pushIFtoStack(output, ptrIFData);
    return frameState;
}

GetFrameStates getFrame(FILE *input, Stack *output, Defines *ptrDefs, ControlFrameData *ptrCFData,
                        InsnFrameData *ptrIFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    switch(ptrLex->lexType){
        case BracketCurlyOpen:
            return processControlFrame(input, output, ptrCFData, ptrLex, ptrLineNum);
        case Colon:
            return processInsnFrame(input, output, ptrDefs, ptrCFData, ptrIFData, ptrLex, ptrLineNum);
        case Nothing:
            return GetFrameEnd;
        default:
            ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое, где символ начала фрейма?");
    }
}

CheckEndStates checkEnd(FILE *input, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType == Nothing)
        return CheckEndReached;
    else
        return CheckEndNotReached;
}

CompilerStates compileFileToStack(FILE* input, Stack* output){
    MEM_CHECK(input, CompilerErrorNullInput, "Error: input file is NULL");
    MEM_CHECK(output, CompilerErrorNullStack, "Error: output stack is NULL");
    Defines defs;
    lexeme lex;
    ControlFrameData CFData;
    InsnFrameData IFData;
    if(allInit(&defs, &lex, &CFData, &IFData) == InitError){
        allFree(&defs, &lex, &CFData, &IFData);
        ERROR_MSG_NL(CompilerErrorMemAlloc, "Error: mem alloc error");
    }

    GetFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;

    do {
        frameState = getFrame(input, output, &defs,
                              &CFData, &IFData, &lex, &lineNum);
    } while(++i < FRAMES_COUNT && frameState == GetFrameOK);

    if(i == FRAMES_COUNT && frameState == GetFrameOK
    && checkEnd(input, &lex, &lineNum) == CheckEndNotReached)
        WARNING_LEX(&lineNum, &lex,
                      "Warning: Out of range, max count of frames has reached - %d",, FRAMES_COUNT);

    if(CFData.IF_Num_left > 0)
        WARNING(&lineNum, "Warning: There are IF needed - %d",, CFData.IF_Num_left);

    allFree(&defs, &lex, &CFData, &IFData);
    switch(frameState){
    case GetFrameOK: case GetFrameEnd:
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
    if(state == CompilerOK)
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