`include "IncAllCore.def.v"

module ALU (
    input wire [`REG_RANGE] src_0_data_ALU,
    input wire [`REG_RANGE] src_1_data_ALU,
    input wire [`REG_RANGE] insn_F2_const_ALU,
    input wire [`CORE_ID_RANGE] core_id,
    input wire insn_set_const_mode,
    input wire [`INSN_OPC_RANGE] DX_insn_opc,
    output wire [`REG_RANGE] X_result_ALU
);

    wire [`REG_RANGE] core_id_extended = {{(`REG_SIZE - `CORE_ID_SIZE){1'b0}}, core_id};
    //fixme: энергоэффективность
    assign X_result_ALU =
         {`REG_SIZE {DX_insn_opc == `ADD}} & {src_0_data_ALU + src_1_data_ALU} //ld в Core
        |{`REG_SIZE {DX_insn_opc == `SUB}} & {src_0_data_ALU - src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `MUL}} & {src_0_data_ALU * src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `DIV}} & {src_0_data_ALU / src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `CMPGE}} & {{(`REG_SIZE - 1){1'b0}}, {src_0_data_ALU >= src_1_data_ALU}}
        |{`REG_SIZE {DX_insn_opc == `RSHIFT}} & {src_0_data_ALU >> src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `LSHIFT}} & {src_0_data_ALU << src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `AND}} & {src_0_data_ALU & src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `OR}} & {src_0_data_ALU | src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `XOR}} & {src_0_data_ALU ^ src_1_data_ALU}
        |{`REG_SIZE {DX_insn_opc == `SET_CONST}} & {(insn_set_const_mode) ? insn_F2_const_ALU : core_id_extended}
        |{`REG_SIZE {DX_insn_opc == `LD | DX_insn_opc == `ST}} & {src_0_data_ALU};

endmodule