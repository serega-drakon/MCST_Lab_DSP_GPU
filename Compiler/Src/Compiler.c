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
#include "TranslateEnumTables.h"

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

#define ERROR_MSG_OP(ptrLineNum, ptrOp, errorCode, errorMsg, ...) \
do { printf("Line %d: ", *(ptrLineNum) + 1);                        \
     printf(errorMsg __VA_ARGS__);                                  \
     printf("\n -> %ls\n", (ptrOp));                           \
     return errorCode; } while(0)

#define ERROR_MSG_OP_NL_FREE_OP(ptrOp, errorCode, errorMsg, ...)\
do { printf(errorMsg __VA_ARGS__);                              \
     printf("\n -> %ls\n", (ptrOp));                            \
     free(ptrOp);                                               \
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

InitStates definesInit(Defines *ptrDef){
    assert(ptrDef != NULL);
    const char errorMsg[] = "Defines memory alloc error";
    ptrDef->ptrLabelDefinedNames = dStackInit(MAX_OP * sizeof(int));
    MEM_CHECK(ptrDef->ptrLabelDefinedNames, InitError, errorMsg);
    ptrDef->ptrLabelDefinedValues = dStackInit(sizeof(unsigned));
    MEM_CHECK(ptrDef->ptrLabelDefinedValues, InitError, errorMsg);
    ptrDef->ptrLabelUsedNames = dStackInit(MAX_OP * sizeof(int));
    MEM_CHECK(ptrDef->ptrLabelUsedNames, InitError, errorMsg);
    ptrDef->ptrLabelUsedValuesPtr = dStackInit(sizeof(Stack *));
    MEM_CHECK(ptrDef->ptrLabelUsedValuesPtr, InitError, errorMsg);
    return InitOK;
}

void definesReset(Defines *ptrDef){
    assert(ptrDef != NULL);
    dStackReset(ptrDef->ptrLabelDefinedNames);
    dStackReset(ptrDef->ptrLabelDefinedValues);
    dStackReset(ptrDef->ptrLabelUsedNames);
    if(ptrDef->ptrLabelUsedValuesPtr != NULL) {
        const u_int32_t size = getsize_dStack(ptrDef->ptrLabelUsedValuesPtr);
        for (int i = 0; i < size; i++)
            dStackFree(*(Stack **) pop_dStack(ptrDef->ptrLabelUsedValuesPtr));
        dStackReset(ptrDef->ptrLabelUsedValuesPtr);
    }
}

void definesFree(Defines *ptrDef){
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

InitStates allInit(Defines *ptrDefs, lexeme *ptrLex, ControlFrameData *ptrCFData,
                   InsnFrameData *ptrIFData){
    if(definesInit(ptrDefs) == InitError
       || lexInit(ptrLex) == InitError
       || controlFrameDataInit(ptrCFData) == InitError
       || insnFrameDataInit(ptrIFData) == InitError)
        return InitError;
    return InitOK;
}

void allFree(Defines *ptrDef, lexeme *ptrLex, ControlFrameData *ptrCFData,
             InsnFrameData *ptrIFData){
    definesFree(ptrDef);
    lexFree(ptrLex);
    controlFrameDataFree(ptrCFData);
    insnFrameDataFree(ptrIFData);
}

///Подфункция getType
LexemeTypes checkConst16(const int op[], const unsigned *ptrLineNum){
    const char errorMsg[] = "Ошибка в определении шестнадцатеричной константы";
    if(op[1] == '\0')
        ERROR_MSG_OP(ptrLineNum, op, Error, errorMsg);
    for (int i = 1; op[i] != '\0'; i++)
        if (!isdigit(op[i]) && (op[i] < 'A' || op[i] > 'F'))
            ERROR_MSG_OP(ptrLineNum, op, Error, errorMsg);
    return Const16;
}

///Подфункция getType
LexemeTypes checkConst10(const int op[], const unsigned *ptrLineNum){
    const char errorMsg[] = "Ошибка в определении десятичной константы";
    if(op[1] == '\0')
        ERROR_MSG_OP(ptrLineNum, op, Error, errorMsg);
    for(int i = 1; op[i] != '\0'; i++)
        if(!isdigit(op[i]))
            ERROR_MSG_OP(ptrLineNum, op, Error, errorMsg);
    return Const10;
}

///Подфункция getType
LexemeTypes checkReg(const int op[], const unsigned *ptrLineNum){
    for(Registers_str_enum i = Registers_str_enum_MIN; i < Registers_str_enum_MAX; i++){
        if(compareStrIntChar(&op[1], Registers_str_[i]))
            return translateRegFromStrToLex(i);
    }
    ERROR_MSG_OP(ptrLineNum, op, Error, "Ошибка в определении регистра");
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

LexemeTypes getType(const int op[], const unsigned *ptrLineNum){
    switch(op[0]){
        case '$': return checkConst16(op, ptrLineNum);
        case '!': return checkConst10(op, ptrLineNum);
        case '%': return checkReg(op, ptrLineNum);
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
        ptrLex->lexType = getType(ptrLex->op, ptrLineNum);
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
            }
            else{
                unGetLex(ptrLex);
                commentEnd = 1;
            }
            ungetc(c, input);
        }
        else{
            unGetLex(ptrLex);
            commentEnd = 1;
        }
    } while(!commentEnd);
}

ProcessStates processGetConst(uint8_t *dst, lexeme *ptrLex){
    switch(ptrLex->lexType){
        case Const10:
            *dst = getConst10D(ptrLex->op);
            return ProcessOK;
        case Const16:
            *dst = getConst16D(ptrLex->op);
            return ProcessOK;
        default:
            //fixme; errors
            return ProcessError;
    }
}

void getLexNoComments(FILE *input, unsigned *ptrLineNum, lexeme *ptrLex){
    skipComments(input, ptrLineNum, ptrLex);
    getLex(input, ptrLineNum, ptrLex);
}

ProcessStates processInitR0(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                            unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != BracketSquareOpen)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо открыть скобочку");
    getLexNoComments(input, ptrLineNum, ptrLex);
    uint8_t index;
    if(processGetConst(&index, ptrLex) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо число");
    getLexNoComments(input, ptrLineNum, ptrLex);;
    if(ptrLex->lexType != BracketSquareClose)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо закрыть скобочку");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    getLexNoComments(input, ptrLineNum, ptrLex);
    uint8_t data;
    if(processGetConst(&data, ptrLex) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо значение");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Semicolon)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут точку с запятой");
    ptrCFData->initR0data[index] = data;
    ptrCFData->initR0Vector[index] = VectorActive;
    return ProcessOK;
}

ProcessStates processCoreActive(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                                unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    do {
        getLexNoComments(input, ptrLineNum, ptrLex);
        uint8_t index;
        if (processGetConst(&index, ptrLex) == ProcessError)
            ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо значение");
        ptrCFData->coreActiveVector[index] = VectorActive;
        getLexNoComments(input, ptrLineNum, ptrLex);
        if (ptrLex->lexType != Comma && ptrLex->lexType != Semicolon)
            ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "А тут надо запятую или точку с запятой");
    } while(ptrLex->lexType != Semicolon);
    return ProcessOK;
}

ProcessStates processFence(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                           unsigned *ptrLineNum){
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

ProcessStates processIFNum(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                           unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Equal)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо знак равно");
    getLexNoComments(input, ptrLineNum, ptrLex);
    uint8_t count;
    if(processGetConst(&count, ptrLex) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо число");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Semicolon)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут точку с запятой");
    ptrCFData->IF_Num_left = count;
    return ProcessOK;
}

GetFrameStates getControlFrame(FILE* input, ControlFrameData *ptrCFData, lexeme *ptrLex,
                               unsigned *ptrLineNum){
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
                ERROR_MSG(ptrLineNum, GetFrameCodeError,
                          "Ожидался \"}\", а получен конец файла... ну и кринжовый ты тип....");
            default:
                ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError, "Чо это такое в CF?");
        }
    } while(ptrLex->lexType != BracketCurlyClose);
    return GetFrameOK;
}

void processInsnWithNoArgs(insnData *ptrInsn, LexemeTypes lexType){
    ptrInsn->opCode = translateLexTypeToInsnOpCode(lexType);
}

ProcessStates processReg(InsnReg *ptrInsnReg, LexemeTypes lexType){
    switch(lexType){
        case Reg_R0:
            *ptrInsnReg = Reg_R0_insn;
            return ProcessOK;
        case Reg_R1:
            *ptrInsnReg = Reg_R1_insn;
            return ProcessOK;
        case Reg_R2:
            *ptrInsnReg = Reg_R2_insn;
            return ProcessOK;
        case Reg_R3:
            *ptrInsnReg = Reg_R3_insn;
            return ProcessOK;
        case Reg_R4:
            *ptrInsnReg = Reg_R4_insn;
            return ProcessOK;
        case Reg_R5:
            *ptrInsnReg = Reg_R5_insn;
            return ProcessOK;
        case Reg_R6:
            *ptrInsnReg = Reg_R6_insn;
            return ProcessOK;
        case Reg_R7:
            *ptrInsnReg = Reg_R7_insn;
            return ProcessOK;
        case Reg_R8:
            *ptrInsnReg = Reg_R8_insn;
            return ProcessOK;
        case Reg_R9:
            *ptrInsnReg = Reg_R9_insn;
            return ProcessOK;
        case Reg_R10:
            *ptrInsnReg = Reg_R10_insn;
            return ProcessOK;
        case Reg_R11:
            *ptrInsnReg = Reg_R11_insn;
            return ProcessOK;
        case Reg_R12:
            *ptrInsnReg = Reg_R12_insn;
            return ProcessOK;
        case Reg_R13:
            *ptrInsnReg = Reg_R13_insn;
            return ProcessOK;
        case Reg_R14:
            *ptrInsnReg = Reg_R14_insn;
            return ProcessOK;
        case Reg_R15:
            *ptrInsnReg = Reg_R15_insn;
            return ProcessOK;
        default:
            return ProcessError;
    }
}

ProcessStates processInsnWithTwoRegs(FILE *input, insnData *ptrInsn, lexeme *ptrLex,
                                     unsigned *ptrLineNum){
    ptrInsn->opCode = translateLexTypeToInsnOpCode(ptrLex->lexType);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processReg(&ptrInsn->src0, ptrLex->lexType) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо регистр");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processReg(&ptrInsn->src1, ptrLex->lexType) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо регистр");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processReg(&ptrInsn->src2dst, ptrLex->lexType) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо регистр");
    return ProcessOK;
}

ProcessStates processInsnWithConstAndReg(FILE *input, insnData *ptrInsn, lexeme *ptrLex,
                                         unsigned *ptrLineNum){
    ptrInsn->opCode = translateLexTypeToInsnOpCode(ptrLex->lexType);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processGetConst(&ptrInsn->constData, ptrLex) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо число");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processReg(&ptrInsn->src2dst, ptrLex->lexType) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо регистр");
    return ProcessOK;
}

void processLabelUsage(Defines *ptrDef, unsigned insnNum, int *labelLexOp){
    int search = searchFor(ptrDef->ptrLabelUsedNames, labelLexOp, MAX_OP);
    Stack* ptrStack;
    if(search == NONE){
        push_dStack(ptrDef->ptrLabelUsedNames, labelLexOp);
        ptrStack = dStackInit(sizeof(unsigned));
        push_dStack(ptrDef->ptrLabelUsedValuesPtr, &ptrStack);
    }
    else
        ptrStack = *(Stack**) dStack_r(ptrDef->ptrLabelUsedValuesPtr, search);
    push_dStack(ptrStack, &insnNum);
}

ProcessStates processInsnWithLabel(FILE *input, Defines *ptrDef, insnData *ptrInsn,
                                   lexeme *ptrLex, unsigned insnNum, unsigned *ptrLineNum){
    ptrInsn->opCode = translateLexTypeToInsnOpCode(ptrLex->lexType);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(processReg(&ptrInsn->src0, ptrLex->lexType) == ProcessError)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо регистр");
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(ptrLex->lexType != Label)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Тут надо метку");
    processLabelUsage(ptrDef, insnNum, ptrLex->op);
    ptrInsn->target = 0;
    return ProcessOK;
}

ProcessStates processLabelDefinition(Defines *ptrDef, lexeme *ptrLex, unsigned insnNum,
                                     const unsigned *ptrLineNum){
    if(searchFor(ptrDef->ptrLabelDefinedNames, ptrLex->op, MAX_OP) != NONE)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, ProcessError, "Метка переопределена");
    push_dStack(ptrDef->ptrLabelDefinedNames, ptrLex->op);
    push_dStack(ptrDef->ptrLabelDefinedValues, &insnNum);
    return ProcessOK;
}

ProcessStates processCheckAndPutLabels(Defines *ptrDef, InsnFrameData *ptrIFData){
    unsigned size = getsize_dStack(ptrDef->ptrLabelUsedNames);
    int search;
    unsigned labelData;
    unsigned insnNum;
    int *buffOp = malloc(MAX_OP);
    Stack *ptrLabelUsedValues;
    for(unsigned i = 0; i < size; i++){
        memcpy(buffOp, dStack_r(ptrDef->ptrLabelUsedNames, i), MAX_OP * sizeof(int));
        search = searchFor(ptrDef->ptrLabelDefinedNames, buffOp, MAX_OP);
        if(search == NONE)
            ERROR_MSG_OP_NL_FREE_OP(buffOp, ProcessError, "Использованная метка не определена");
        labelData = *(unsigned *)dStack_r(ptrDef->ptrLabelDefinedValues, search);
        ptrLabelUsedValues = *(Stack**) dStack_r(ptrDef->ptrLabelUsedValuesPtr, i);
        insnNum = *(unsigned *) pop_dStack(ptrLabelUsedValues);
        ptrIFData->ptrInsn[insnNum].target = labelData;
    }
    free(buffOp);
    return ProcessOK;
}

GetFrameStates getInsnFrame(FILE *input, Defines *ptrDef, InsnFrameData *ptrIFData,
                            lexeme *ptrLex, unsigned *ptrLineNum){
    unsigned insnNum = 0;
    do{
        getLexNoComments(input, ptrLineNum, ptrLex);
        switch (ptrLex->lexType) { // оп оп грамматика пошла
            case Nop: case Ready:
                processInsnWithNoArgs(&ptrIFData->ptrInsn[insnNum], ptrLex->lexType);
                insnNum++;
                break;
            case Add: case Sub: case Mul: case Div: case Cmpge: case Rshift:
            case Lshift: case And: case Or: case Xor: case Ld:  case St:
                if(processInsnWithTwoRegs(input, &ptrIFData->ptrInsn[insnNum],
                                          ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError, "Error: Insn with two regs error");
                insnNum++;
                break;
            case Set_const:
                if(processInsnWithConstAndReg(input, &ptrIFData->ptrInsn[insnNum],
                                              ptrLex, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError,
                              "Error: Insn with reg and Const error");
                insnNum++;
                break;
            case Bnz:
                if(processInsnWithLabel(input, ptrDef, &ptrIFData->ptrInsn[insnNum],
                                        ptrLex, insnNum, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError,
                              "Error: Insn with reg and Const error");
                insnNum++;
                break;
            case Label:
                if(processLabelDefinition(ptrDef, ptrLex, insnNum, ptrLineNum) == ProcessError)
                    ERROR_MSG(ptrLineNum, GetFrameCodeError,
                              "Error: Label definition error");
                break;
            case Colon: case BracketCurlyOpen: case Nothing:
                unGetLex(ptrLex);
                break;
            default:
                ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError,
                              "Чо это такое в IF?");
        }
    } while(insnNum < INSN_COUNT
    && ptrLex->lexType != Nothing
    && ptrLex->lexType != Colon
    && ptrLex->lexType != BracketCurlyOpen);
    getLexNoComments(input, ptrLineNum, ptrLex);
    if(insnNum == INSN_COUNT
    && ptrLex->lexType != Nothing
    && ptrLex->lexType != Colon
    && ptrLex->lexType != BracketCurlyOpen)
        ERROR_MSG_LEX(ptrLineNum, ptrLex, GetFrameCodeError,
                      "Уже наступил конец фрейма, всего комманд может быть - %d",, INSN_COUNT);
    unGetLex(ptrLex);
    if(processCheckAndPutLabels(ptrDef, ptrIFData) == ProcessError)
        ERROR_MSG_NL(GetFrameCodeError, "Чот тут метки не сходятся");
    return GetFrameOK;
}

CheckCFFlags checkCFFlags(ControlFrameData *ptrCFData){
    assert(ptrCFData != NULL && ptrCFData->initR0Vector != NULL
           && ptrCFData->coreActiveVector != NULL);
    for(unsigned i = 0; i < CORES_COUNT; i++){
        if(ptrCFData->initR0Vector[i] == VectorActive
        && ptrCFData->coreActiveVector[i] == VectorNoActive)
            return CheckCFFlagsWarning;
    }
    return CheckCFFlagsSuccess;
}

void resetData(unsigned char data[]){
    for(unsigned i = 0; i < INSN_SIZE; i++)
        data[i] = 0;
}

// 0 - старший, 1 - младший байты
void putHeader(unsigned char data[], const ControlFrameData *ptrCFData){
    resetData(data);
    data[0] = RESERVED;
    unsigned char fenceMode_insn = translateFenceModesToInsn(ptrCFData->fenceMode);
    data[1] |= fenceMode_insn << 6;
    unsigned char IF_Num = ptrCFData->IF_Num_left;
    data[1] |= (IF_Num << 2) >> 2; //todo: overflow check
}

void putCoreActive(unsigned char data[], const ControlFrameData *ptrCFData){
    resetData(data);
    for(unsigned i = 0; i < 8; i++)
        if(ptrCFData->coreActiveVector[i] == VectorActive)
            data[1] |= 1 << i;
    for(unsigned i = 8; i < CORES_COUNT; i++)
        if(ptrCFData->coreActiveVector[i] == VectorActive)
            data[0] |= 1 << (i - 8);
}

void putInitR0Vect(unsigned char data[], const ControlFrameData *ptrCFData){
    resetData(data);
    for(unsigned i = 0; i < 8; i++)
        if(ptrCFData->initR0Vector[i] == VectorActive)
            data[1] |= 1 << i;
    for(unsigned i = 8; i < CORES_COUNT; i++)
        if(ptrCFData->initR0Vector[i] == VectorActive)
            data[0] |= 1 << (i - 8);
}

void putReserved(unsigned char data[], const ControlFrameData *ptrCFData){
    for(unsigned i = 0; i < INSN_SIZE; i++)
        data[i] = RESERVED;
}

void pushCFtoStack(Stack *output, const ControlFrameData *ptrCFData){
    unsigned char data[INSN_SIZE];
    putHeader(data, ptrCFData);
    push_dStack(output, data);
    putCoreActive(data, ptrCFData);
    push_dStack(output, data);
    putInitR0Vect(data, ptrCFData);
    push_dStack(output, data);
    putReserved(data, ptrCFData);
    for(unsigned i = 0; i < 5; i++)
        push_dStack(output, data);
    for(unsigned i = 0; i < CORES_COUNT / 2; i++){
        data[0] = ptrCFData->initR0data[2 * i + 1];
        data[1] = ptrCFData->initR0data[2 * i];
        push_dStack(output, data);
    }
}

GetFrameStates processControlFrame(FILE* input, Stack *output, ControlFrameData *ptrCFData,
                                   lexeme *ptrLex, unsigned *ptrLineNum){
    if(ptrCFData->IF_Num_left > 0)
        WARNING(ptrLineNum, "Warning: There are IFs left - %d",, ptrCFData->IF_Num_left);
    controlFrameDataReset(ptrCFData);
    GetFrameStates frameState = getControlFrame(input, ptrCFData, ptrLex, ptrLineNum);
    if(checkCFFlags(ptrCFData) == CheckCFFlagsWarning)
        WARNING(ptrLineNum, "Warning: InitR0 > CoreActive???");
    pushCFtoStack(output, ptrCFData);
    return frameState;
}

// 0 - старший, 1 - младший байты
void putOpCode(unsigned char insn[], InsnOpCodes opCode){
    insn[0] |= ((unsigned char) opCode) << 4;
}

void putSrc0(unsigned char insn[], InsnReg src0){
    insn[0] |= (((unsigned char) src0) << 4) >> 4;
}

void putSrc1(unsigned char insn[], InsnReg src1){
    insn[1] |= ((unsigned char) src1) << 4;
}

void putSrc2Dst(unsigned char insn[], InsnReg src2dst){
    insn[1] |= (((unsigned char) src2dst) << 4) >> 4;
}

void putConst(unsigned char insn[], unsigned char constData){
    insn[0] |= ((unsigned char) constData) >> 4;
    insn[1] |= ((unsigned char) constData) << 4;
}

void putTarget(unsigned char insn[], unsigned char target){
    insn[1] |= ((unsigned char) target) << 4;
}

void pushSrc0Src1Src2Dst(unsigned char insn[], const insnData *ptrInsnData){
    resetData(insn);
    putOpCode(insn, ptrInsnData->opCode);
    putSrc0(insn, ptrInsnData->src0);
    putSrc1(insn, ptrInsnData->src1);
    putSrc2Dst(insn, ptrInsnData->src2dst);
}

void pushSrc0Target(unsigned char insn[], const insnData *ptrInsnData){
    resetData(insn);
    putOpCode(insn, ptrInsnData->opCode);
    putSrc0(insn, ptrInsnData->src0);
    putTarget(insn, ptrInsnData->target);
}

void pushConstDst(unsigned char insn[], const insnData *ptrInsnData){
    resetData(insn);
    putOpCode(insn, ptrInsnData->opCode);
    putConst(insn, ptrInsnData->constData);
    putSrc2Dst(insn, ptrInsnData->src2dst);
}

void pushOpCode(unsigned char insn[], const insnData *ptrInsnData){
    resetData(insn);
    putOpCode(insn, ptrInsnData->opCode);
}

void pushIFtoStack(Stack *output, const InsnFrameData *ptrIFData){
    unsigned char insn[INSN_SIZE];
    for(unsigned i = 0; i < INSN_COUNT; i++){
        switch (ptrIFData->ptrInsn[i].opCode) {
            case Add_insn:
            case Sub_insn:
            case Mul_insn:
            case Div_insn:
            case Cmpge_insn:
            case Rshift_insn:
            case Lshift_insn:
            case And_insn:
            case Or_insn:
            case Xor_insn:
            case Ld_insn:
            case St_insn:
                pushSrc0Src1Src2Dst(insn, &ptrIFData->ptrInsn[i]);
                break;
            case Set_const_insn:
                pushConstDst(insn, &ptrIFData->ptrInsn[i]);
                break;
            case Bnz_insn:
                pushSrc0Target(insn, &ptrIFData->ptrInsn[i]);
                break;
            case Nop_insn:
            case Ready_insn:
                pushOpCode(insn, &ptrIFData->ptrInsn[i]);
                break;
            default:
                assert(0);
        }
        push_dStack(output, insn);
    }
}

GetFrameStates processInsnFrame(FILE* input, Stack *output, Defines *ptrDef, ControlFrameData *ptrCFData,
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
    GetFrameStates frameState = getInsnFrame(input, ptrDef, ptrIFData, ptrLex, ptrLineNum);
    pushIFtoStack(output, ptrIFData);
    definesReset(ptrDef);
    insnFrameDataReset(ptrIFData);
    return frameState;
}

GetFrameStates getFrame(FILE *input, Stack *output, Defines *ptrDef, ControlFrameData *ptrCFData,
                        InsnFrameData *ptrIFData, lexeme *ptrLex, unsigned *ptrLineNum){
    getLexNoComments(input, ptrLineNum, ptrLex);
    switch(ptrLex->lexType){
        case BracketCurlyOpen:
            return processControlFrame(input, output, ptrCFData, ptrLex, ptrLineNum);
        case Colon:
            return processInsnFrame(input, output, ptrDef, ptrCFData, ptrIFData, ptrLex, ptrLineNum);
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
    Defines def;
    lexeme lex;
    ControlFrameData CFData;
    InsnFrameData IFData;
    if(allInit(&def, &lex, &CFData, &IFData) == InitError){
        allFree(&def, &lex, &CFData, &IFData);
        ERROR_MSG_NL(CompilerErrorMemAlloc, "Error: mem alloc error");
    }
    GetFrameStates frameState;
    unsigned int lineNum = 0; ///< номер строки минус 1
    unsigned int i = 0;
    do {
        frameState = getFrame(input, output, &def,
                              &CFData, &IFData, &lex, &lineNum);
    } while(++i < FRAMES_COUNT && frameState == GetFrameOK);

    if(i == FRAMES_COUNT && frameState == GetFrameOK
    && checkEnd(input, &lex, &lineNum) == CheckEndNotReached)
        WARNING_LEX(&lineNum, &lex,
                      "Warning: Out of range, max count of frames has reached - %d",, FRAMES_COUNT);

    if(CFData.IF_Num_left > 0)
        WARNING(&lineNum, "Warning: There are IF needed - %d",, CFData.IF_Num_left);

    allFree(&def, &lex, &CFData, &IFData);
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
    unsigned size = getsize_dStack(input);
    unsigned char *ptrValue;
    unsigned i = 0;
    while(i < size){
        do {
            do {
                ptrValue = dStack_r(input, i++);
                fprintf(output, "%.2x%.2x ", ptrValue[0], ptrValue[1]);
            } while (i % 4 != 0 && i < size);
            fprintf(output, "\n");
        } while(i % (4 * 4) != 0 && i < size);
        fprintf(output, "\n");
    }
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
    if(state == CompilerOK)
        printProgramFromStackToBin(ptrProgram, output);
    dStackFree(ptrProgram);
    return state;
}