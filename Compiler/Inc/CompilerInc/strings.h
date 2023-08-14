//
// Created by Сергей Слепышев on 07.08.2023.
// всякие строки для компилятора

#ifndef DSP_GPU_COMPILER_STRINGS_H
#define DSP_GPU_COMPILER_STRINGS_H

extern const char *Registers_str_[];
extern const char *OpCodes_str_[];
extern const char *CFParamNames_str_[];
extern const char *FenceModes_str_[];

typedef enum Registers_str_enum_{
    Registers_str_enum_MIN = 0,
    Reg_R0_str = Registers_str_enum_MIN,
    Reg_R1_str,
    Reg_R2_str,
    Reg_R3_str,
    Reg_R4_str,
    Reg_R5_str,
    Reg_R6_str,
    Reg_R7_str,
    Reg_R8_str,
    Reg_R9_str,
    Reg_R10_str,
    Reg_R11_str,
    Reg_R12_str,
    Reg_R13_str,
    Reg_R14_str,
    Reg_R15_str,
    Registers_str_enum_MAX
} Registers_str_enum;

typedef enum OpCodes_str_enum_{
    OpCodes_str_enum_MIN = 0,
    Nop_str = OpCodes_str_enum_MIN,
    Add_str,
    Sub_str,
    Mul_str,
    Div_str,
    Cmpge_str,
    Rshift_str,
    Lshift_str,
    And_str,
    Or_str,
    Xor_str,
    Ld_str,
    Set_const_str,
    St_str,
    Bnz_str,
    Ready_str,
    OpCodes_str_enum_MAX
} OpCodes_str_enum;

typedef enum CFParamNames_str_enum_{
    CFParamNames_str_enum_MIN = 0,
    InitR0_str = CFParamNames_str_enum_MIN,
    CoreActive_str,
    Fence_str,
    IFNum_str,
    CFParamNames_str_enum_MAX
} CFParamNames_str_enum;

typedef enum FenceModes_str_enum_{
    FenceModes_str_enum_MIN = 0,
    FenceNo_str = FenceModes_str_enum_MIN,
    FenceAcq_str,
    FenceRel_str,
    FenceModes_str_enum_MAX
} FenceModes_str_enum;

#endif //DSP_GPU_COMPILER_STRINGS_H
