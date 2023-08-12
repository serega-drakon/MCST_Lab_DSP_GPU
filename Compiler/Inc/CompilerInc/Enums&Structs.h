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
    Semicolon,
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

typedef enum VectorStates_{
    VectorNoActive = 0,
    VectorActive
} VectorStates;

typedef enum FenceModes_{
    FenceNo_mode = 0,
    FenceAcq_mode,
    FenceRel_mode
} FenceModes;

///Вспомогательные данные для поиска ошибок
typedef struct FrameData_{
    unsigned IF_Num_left;
    VectorStates *coreActiveVector;
    VectorStates *initR0Vector;
    uint8_t *initR0data;
    FenceModes fenceMode;
} ControlFrameData;

typedef enum UnGetLexStatus_{
    UnGetLexFalse = 0,
    UnGetLexTrue
} UnGetLexStatus;

typedef struct lexeme_{
    int *op;
    LexemeTypes lexType;
    UnGetLexStatus unGetStatus;
} lexeme;

typedef struct insn_{
    InsnOpCodes opCode;
    InsnSrcDst src0;
    InsnSrcDst src1;
    InsnSrcDst src2dst;
    uint8_t constData;
    uint8_t target;
} insn;

typedef enum InitStates_{
    InitOK,
    InitError
} InitStates;

typedef enum getFrameStates_{
    GetFrameEnd = -1, ///< если конец достигнут
    GetFrameOk = 0, ///< если конец не достигнут
    GetFrameCodeError = 1 ///< если возникла ошибка
} GetFrameStates;

typedef enum CheckEndStates_{
    CheckEndReached,
    CheckEndNotReached
} CheckEndStates;

typedef enum CheckCFFlags_{
    CheckCFFlagsSuccess = 0,
    CheckCFFlagsWarning
} CheckCFFlags;

typedef enum ProcessStates_{
    ProcessOK,
    ProcessError
} ProcessStates;

#endif //DSP_GPU_COMPILER_ENUMS_STRUCTS_H
