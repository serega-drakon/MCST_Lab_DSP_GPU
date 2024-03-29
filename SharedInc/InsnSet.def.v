`ifndef INSN_SET
`define INSN_SET

`define NOP 4'h0
`define ADD 4'h1
`define SUB 4'h2
`define MUL 4'h3
`define DIV 4'h4
`define CMPGE 4'h5
`define RSHIFT 4'h6
`define LSHIFT 4'h7
`define AND 4'h8
`define OR 4'h9
`define XOR 4'ha
`define LD 4'hb
`define SET_CONST 4'hc
`define ST 4'hd
`define BNZ 4'he
`define READY 4'hf

`endif // INSN_SET