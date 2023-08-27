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
        case CFLabel_str: return CFLabel;
        case NextCF_str: return NextCF;
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

FenceModes_insn translateFenceModesToInsn(FenceModes fenceMode){
    switch(fenceMode){
        case FenceNo_mode: return FenceNo_insn;
        case FenceAcq_mode: return FenceAcq_insn;
        case FenceRel_mode: return FenceRel_insn;
        default: assert(0);
    }
}