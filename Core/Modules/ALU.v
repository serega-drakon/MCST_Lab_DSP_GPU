`include "Inc/Instruction Set.def.v"
`include "Inc/Constants.def.v"

module ALU (
    input wire [`REG_RANGE] src_0_data_ALU,
    input wire [`REG_RANGE] src_1_data_ALU,
    input wire [`INSN_OPC_RANGE] DX_insn_opc,
    output wire [`REG_RANGE] X_result_ALU,
    output wire X_branch_cond_ALU
);

    assign X_branch_cond_ALU = src_0_data_ALU != 0; //тут только bnz

    assign X_result_ALU = {`REG_SIZE {DX_insn_opc == `ADD}} & {src_0_data_ALU+src_1_data_ALU} //ld в Core
        |{`REG_SIZE {DX_insn_opc == `SUB}} & {src_0_data_ALU-src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `MUL}} & {src_0_data_ALU*src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `DIV}} & {src_0_data_ALU/src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `CMPGE}} & {{(`REG_SIZE - 1){1'b0}}, {src_0_data_ALU >= src_1_data_ALU}}
        |{`REG_SIZE {DX_insn_opc == `RSHIFT}} & {src_0_data_ALU >> src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `LSHIFT}} & {src_0_data_ALU << src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `AND}} & {src_0_data_ALU & src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `OR}} & {src_0_data_ALU | src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `XOR}} & {src_0_data_ALU ^ src_1_data_ALU};

endmodule