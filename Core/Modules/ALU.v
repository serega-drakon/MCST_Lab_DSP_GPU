`include "Inc/Instruction Set.vh"
`include "Inc/Constants.vh"

module ALU #(
    parameter REG_SIZE = `REG_SIZE,
    parameter INSN_OPC_SIZE =`INSN_OPC_SIZE
)(
    input wire [REG_SIZE - 1 : 0] src_0_data_ALU,
    input wire [REG_SIZE - 1 : 0] src_1_data_ALU,
    input wire [INSN_OPC_SIZE - 1 : 0] DX_insn_opc,
    output wire [REG_SIZE - 1 : 0] X_result_ALU,
    output wire X_branch_cond_ALU
);

    assign X_branch_cond_ALU = src_0_data_ALU != 0; //тут только bnz

    assign X_result_ALU = {REG_SIZE {DX_insn_opc == `ADD}} & {src_0_data_ALU+src_1_data_ALU} //ld в Core
        |{REG_SIZE {DX_insn_opc == `SUB}} & {src_0_data_ALU-src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `MUL}} & {src_0_data_ALU*src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `DIV}} & {src_0_data_ALU/src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `CMPGE}} & {{(REG_SIZE - 1){1'b0}}, {src_0_data_ALU >= src_1_data_ALU}}
        |{REG_SIZE {DX_insn_opc == `RSHIFT}} & {src_0_data_ALU >> src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `LSHIFT}} & {src_0_data_ALU << src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `AND}} & {src_0_data_ALU & src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `OR}} & {src_0_data_ALU | src_1_data_ALU}
        |{REG_SIZE {DX_insn_opc == `XOR}} & {src_0_data_ALU ^ src_1_data_ALU};

endmodule