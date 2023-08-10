//
// Created by Сергей Слепышев on 09.08.2023.
//

#ifndef DSP_GPU_COMPILER_ENUMS_STRUCTS_H
#define DSP_GPU_COMPILER_ENUMS_STRUCTS_H

#include "Compiler.h"
#include "dStack.h"
#include "encodings.h"

typedef enum LexemeTypes_ {
    Error = -1,
    Nothing = 0,
    Nop,
    Add,
    Sub,
    Mul,
    Div,
    Cmpge,
    Rshift,
    Lshift,
    And,
    Or,
    Xor,
    Ld,
    Set_const,
    St,
    Bnz,
    Ready,
    Reg_R0,
    Reg_R1,
    Reg_R2,
    Reg_R3,
    Reg_R4,
    Reg_R5,
    Reg_R6,
    Reg_R7,
    Reg_R8,
    Reg_R9,
    Reg_R10,
    Reg_R11,
    Reg_R12,
    Reg_R13,
    Reg_R14,
    Reg_R15,
    Const16,
    Const10,
    Label,
    BracketCurlyOpen,
    BracketCurlyClose,
    BracketSquareOpen,
    BracketSquareClose,
    Name,
    Comma,  // в переводе запятая
    Equal,
    Slash,
    InitR0,
    CoreActive,
    Fence,
    IFNum,
    Colon,
    FenceNo,
    FenceAcq,
    FenceRel,
} LexemeTypes;

///Набор динамических массивов, которые я использую
typedef struct Defines_{
    Stack* ptrLabelDefinedNames;       ///<имена меток
    Stack* ptrLabelDefinedValues;      ///<величины меток
    Stack* ptrLabelUsedNames;
    Stack* ptrLabelUsedValuesPtr;
} Defines;

///Вспомогательные данные для поиска ошибок
typedef struct FrameData_{
    unsigned IF_Num_left;
    char *CoreActiveVector;
    char *InitR0Vector;
} FrameData;

typedef enum DefinesInitStates_{
    DefinesInitOK = 0,
    DefinesInitError
} DefinesInitStates;

typedef enum UnGetLexStatus_{
    UnGetLexFalse = 0,
    UnGetLexTrue
} UnGetLexStatus;

typedef struct lexeme_{
    int *op;
    LexemeTypes lexType;
    UnGetLexStatus unGetStatus;
} lexeme;

typedef enum LexInitStates_{
    LexInitSuccess = 0,
    LexInitError
} LexInitStates;

typedef enum FrameDataInitStates_{
    FrameDataInitSuccess = 0,
    FrameDataInitError
} FrameDataInitStates;

typedef enum getFrameStates_{
    GetFrameEnd = -1, ///< если конец достигнут
    GetFrameOk = 0, ///< если конец не достигнут
    GetFrameCodeError = 1 ///< если возникла ошибка
} GetFrameStates;

typedef enum CheckEndStates_{
    CheckEndReached,
    CheckEndNotReached
} CheckEndStates;

#endif //DSP_GPU_COMPILER_ENUMS_STRUCTS_H
