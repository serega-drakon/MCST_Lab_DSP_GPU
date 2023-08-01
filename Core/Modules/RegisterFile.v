module RegisterFile #(
    CORE_NUM = 0
)(
    input wire reset,
    input wire clk,

    input wire init_R0, //если включен, то меняем R0
    input wire [REG_SIZE - 1 : 0] init_R0_data,

    input wire [REG_SIZE - 1 : 0] W_result,
    input wire [REG_PTR_SIZE - 1 : 0] FD_insn_src_0,
    input wire [REG_PTR_SIZE - 1 : 0] FD_insn_src_1,
    input wire [REG_PTR_SIZE - 1 : 0] MW_insn_dst,
    input wire FD_insn_is_F0,
    input wire FD_insn_is_F1,
    input wire FD_insn_is_F2,
    input wire FD_insn_is_F3,
    input wire FD_insn_is_F4,
    output wire [REG_SIZE - 1 : 0] src_0_data,
    output wire [REG_SIZE - 1 : 0] src_1_data
);
    localparam REG_COUNT = `REG_COUNT;
    localparam REG_SIZE = `REG_SIZE;
    localparam REG_PTR_SIZE = `REG_PTR_SIZE;

    reg [REG_SIZE - 1 : 0] r [REG_COUNT - 1 : 0];

endmodule