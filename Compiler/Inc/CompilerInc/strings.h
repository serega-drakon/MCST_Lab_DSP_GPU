//
// Created by Сергей Слепышев on 07.08.2023.
// всякие строки для компилятора

#ifndef DSP_GPU_COMPILER_STRINGS_H
#define DSP_GPU_COMPILER_STRINGS_H

///Представления регистров %..
const char *Registers_str_[] = { //емае пошло говно по трубам
        "r0",
        "r1",
        "r2",
        "r3",
        "r4",
        "r5",
        "r6",
        "r7",
        "r8",
        "r9",
        "r10",
        "r11",
        "r12",
        "r13",
        "r14",
        "r15"
};

typedef enum Registers_str_enum_{
    Reg_R0_str = 0,
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
    Reg_R15_str
} Registers_str_enum;

const char *OpCodes_str_[] = {
    "nop",
    "add",
    "sub",
    "mul",
    "div",
    "cmpge",
    "rshift",
    "lshift",
    "and",
    "or",
    "xor",
    "ld",
    "set_const",
    "st",
    "bnz",
    "ready"
};

typedef enum OpCodes_str_enum_{
    Nop_str = 0,
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
} OpCodes_str_enum;

#endif //DSP_GPU_COMPILER_STRINGS_H
