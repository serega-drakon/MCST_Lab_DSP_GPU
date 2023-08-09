//
// Created by Сергей Слепышев on 07.08.2023.
//

#ifndef DSP_GPU_COMPILER_ENCODINGS_H
#define DSP_GPU_COMPILER_ENCODINGS_H

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

enum OpCodes_ {
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
};

#endif //DSP_GPU_COMPILER_ENCODINGS_H
