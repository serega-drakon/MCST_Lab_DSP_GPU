//
// Created by Сергей Слепышев on 07.08.2023.
// всякие строки для компилятора

#ifndef DSP_GPU_COMPILER_STRINGS_H
#define DSP_GPU_COMPILER_STRINGS_H

///Представления регистров %..
const char *registers_str_[] = { //емае пошло говно по трубам
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

/*typedef enum Registers_str_enum_{
    //FIXME
} Registers_str_enum;

const char *opcodes_str_[]{
    //FIXME
};

typedef enum OpCodes_str_enum_{
    //FIXME
} OpCodes_str_enum;*/

#endif //DSP_GPU_COMPILER_STRINGS_H
