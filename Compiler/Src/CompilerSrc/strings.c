//
// Created by Сергей Слепышев on 14.08.2023.
//

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

const char *CFParamNames_str_[] = {
        "InitR0",
        "CoreActive",
        "Fence",
        "IFNum",
        "CFLabel",
        "NextCF"
};

const char *FenceModes_str_[] = {
        "no",
        "acq",
        "rel"
};
