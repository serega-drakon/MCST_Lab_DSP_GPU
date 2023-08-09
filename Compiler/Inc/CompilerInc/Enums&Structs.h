//
// Created by Сергей Слепышев on 09.08.2023.
//

#ifndef DSP_GPU_COMPILER_ENUMS_STRUCTS_H
#define DSP_GPU_COMPILER_ENUMS_STRUCTS_H

#include "Compiler.h"
#include "dStack.h"
#include "encodings.h"

///Набор динамических массивов, которые я использую
typedef struct Defines_{
    Stack* ptrLabelDefinedNames;       ///<имена меток
    Stack* ptrLabelDefinedValues;      ///<величины меток
    Stack* ptrLabelUsedNames;
    Stack* ptrLabelUsedValuesPtr;
} Defines;

typedef enum DefinesInitStates_{
    DefinesInitOK = 0,
    DefinesInitError
} DefinesInitStates;

typedef enum UnGetLexStatus_{
    UnGetLexFalse = 0,
    UnGetLexTrue
} UnGetLexStatus;

typedef struct lexeme_{
    int op[MAX_OP];
    LexemeTypes lexType;
    UnGetLexStatus unGetStatus;
} lexeme;

typedef enum getFrameStates_{
    GetFrameEnd = -1, ///< если конец достигнут
    GetFrameOk = 0 ///< если конец не достигнут
} getFrameStates;

typedef enum CheckEndStates_{
    CheckEndReached,
    CheckEndNotReached
} CheckEndStates;

typedef enum SkipCommentsState_{
    SkipCommentsSuccess,
    SkipCommentsError
} SkipCommentsState;
#endif //DSP_GPU_COMPILER_ENUMS_STRUCTS_H
