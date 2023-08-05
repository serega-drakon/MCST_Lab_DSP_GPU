//
// Created by Сергей Слепышев on 04.08.2023.
//

#ifndef MCST_LAB_DSP_GPU_COMPILER_H
#define MCST_LAB_DSP_GPU_COMPILER_H

#define FRAMES_COUNT 16
#define INSN_SIZE (2 * sizeof(char))
#define CORES_COUNT 16
#define REG_COUNT 16
#define REG_SIZE (1 * sizeof(char))

#define MAX_OP 32

#define OK 0
#define ERROR (-1)

typedef enum CompilerStates_ {
    CompilerOK,
    CompilerErrorNullInput,
    CompilerErrorNullStack,
    CompilerErrorMemAlloc
} CompilerStates;

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

typedef enum OpTypes_ {
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
    Reg,
    Const16 = Reg + REG_COUNT,
    Const10,
    Label,
    BraceOpen,
    BraceClose,
    IFName,
    Comma
} OpTypes;

CompilerStates compileTextToText(FILE* input, FILE* output);

#endif //MCST_LAB_DSP_GPU_COMPILER_H
