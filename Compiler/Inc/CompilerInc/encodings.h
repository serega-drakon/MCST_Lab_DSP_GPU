//
// Created by Сергей Слепышев on 07.08.2023.
//

#ifndef DSP_GPU_COMPILER_ENCODINGS_H
#define DSP_GPU_COMPILER_ENCODINGS_H

typedef enum FenceModes_insn_{
    FenceNo_insn = 0x0,
    FenceAcq_insn = 0x1,
    FenceRel_insn = 0x2,
} FenceModes_insn_;

typedef enum InsnOpCodes_ {
    Nop_insn = 0x0,
    Add_insn = 0x1,
    Sub_insn = 0x2,
    Mul_insn = 0x3,
    Div_insn = 0x4,
    Cmpge_insn = 0x5,
    Rshift_insn = 0x6,
    Lshift_insn = 0x7,
    And_insn = 0x8,
    Or_insn = 0x9,
    Xor_insn = 0xA,
    Ld_insn = 0xB,
    Set_const_insn = 0xC,
    St_insn = 0xD,
    Bnz_insn = 0xE,
    Ready_insn = 0xF
} InsnOpCodes;

typedef enum InsnReg_{
    Reg_R0_insn = 0x0,
    Reg_R1_insn = 0x1,
    Reg_R2_insn = 0x2,
    Reg_R3_insn = 0x3,
    Reg_R4_insn = 0x4,
    Reg_R5_insn = 0x5,
    Reg_R6_insn = 0x6,
    Reg_R7_insn = 0x7,
    Reg_R8_insn = 0x8,
    Reg_R9_insn = 0x9,
    Reg_R10_insn = 0xA,
    Reg_R11_insn = 0xB,
    Reg_R12_insn = 0xC,
    Reg_R13_insn = 0xD,
    Reg_R14_insn = 0xE,
    Reg_R15_insn = 0xF
} InsnReg;

#endif //DSP_GPU_COMPILER_ENCODINGS_H
