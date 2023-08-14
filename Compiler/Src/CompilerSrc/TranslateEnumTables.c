//
// Created by Сергей Слепышев on 14.08.2023.
//

#include "TranslateEnumTables.h"
#include <assert.h>

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

InsnOpCodes translateLexTypeToInsnOpCode(LexemeTypes lexType){
    switch(lexType){
        case Nop: return Nop_insn;
        case Add: return Add_insn;
        case Sub: return Sub_insn;
        case Mul: return Mul_insn;
        case Div: return Div_insn;
        case Cmpge: return Cmpge_insn;
        case Rshift: return Rshift_insn;
        case Lshift: return Lshift_insn;
        case And: return And_insn;
        case Or: return Or_insn;
        case Xor: return Xor_insn;
        case Ld: return Ld_insn;
        case Set_const: return Set_const_insn;
        case St: return St_insn;
        case Bnz: return Bnz_insn;
        case Ready: return Ready_insn;
        default: assert(0);
    }
}

InsnReg translateLexTypeToInsnReg(LexemeTypes lexType){
    switch(lexType){
        case Reg_R0: return Reg_R0_insn;
        case Reg_R1: return Reg_R1_insn;
        case Reg_R2: return Reg_R2_insn;
        case Reg_R3: return Reg_R3_insn;
        case Reg_R4: return Reg_R4_insn;
        case Reg_R5: return Reg_R5_insn;
        case Reg_R6: return Reg_R6_insn;
        case Reg_R7: return Reg_R7_insn;
        case Reg_R8: return Reg_R8_insn;
        case Reg_R9: return Reg_R9_insn;
        case Reg_R10: return Reg_R10_insn;
        case Reg_R11: return Reg_R11_insn;
        case Reg_R12: return Reg_R12_insn;
        case Reg_R13: return Reg_R13_insn;
        case Reg_R14: return Reg_R14_insn;
        case Reg_R15: return Reg_R15_insn;
        default: assert(0);
    }
}

uint8_t isRegLex(LexemeTypes lexType){
    return (lexType == Reg_R0
            || lexType == Reg_R1
            || lexType == Reg_R2
            || lexType == Reg_R3
            || lexType == Reg_R4
            || lexType == Reg_R5
            || lexType == Reg_R6
            || lexType == Reg_R7
            || lexType == Reg_R8
            || lexType == Reg_R9
            || lexType == Reg_R10
            || lexType == Reg_R11
            || lexType == Reg_R12
            || lexType == Reg_R13
            || lexType == Reg_R14
            || lexType == Reg_R15);
}

uint8_t isConst(LexemeTypes lexType){
    return (lexType == Const10 || lexType == Const16);
}
