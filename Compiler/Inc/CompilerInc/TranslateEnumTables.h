//
// Created by Сергей Слепышев on 14.08.2023.
//

#ifndef DSP_GPU_COMPILER_TRANSLATEENUMTABLES_H
#define DSP_GPU_COMPILER_TRANSLATEENUMTABLES_H

#include "strings.h"
#include "encodings.h"
#include "Enums&Structs.h"

LexemeTypes translateRegFromStrToLex(Registers_str_enum strEnum);
LexemeTypes translateOpCodeFromStrToLex(OpCodes_str_enum strEnum);
LexemeTypes translateCFParamNamesFromStrToLex(CFParamNames_str_enum strEnum);
LexemeTypes translateFenceModesFromStrToLex(FenceModes_str_enum strEnum);
InsnOpCodes translateLexTypeToInsnOpCode(LexemeTypes lexType);
InsnReg translateLexTypeToInsnReg(LexemeTypes lexType);
uint8_t isRegLex(LexemeTypes lexType);
uint8_t isConst(LexemeTypes lexType);

#endif //DSP_GPU_COMPILER_TRANSLATEENUMTABLES_H
