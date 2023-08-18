`include "IncAllCore.def.v"

module RegisterFile (
    input wire clk,
    input wire reset_RF,

    input wire init_R0, //если включен, то меняем R0
    input wire [`REG_RANGE] init_R0_data,

    input wire [`REG_RANGE] W_result, // за отбор результата отвечает Core
    input wire [`REG_PTR_RANGE] FD_insn_src_0,
    input wire [`REG_PTR_RANGE] FD_insn_src_1,
    input wire [`REG_PTR_RANGE] FD_insn_src_2,
    input wire [`REG_PTR_RANGE] MW_insn_dst,
    input wire MW_insn_is_F1,
    input wire MW_insn_is_F2,
    output wire [`REG_RANGE] D_src_0_data,
    output wire [`REG_RANGE] D_src_1_data,
    output wire [`REG_RANGE] D_src_2_data
);
    reg [`REG_RANGE] r [`REG_COUNT - 1 : 0];

    assign D_src_0_data = r[FD_insn_src_0];
    assign D_src_1_data = r[FD_insn_src_1];
    assign D_src_2_data = r[FD_insn_src_2];

    wire get_result_flag [`REG_COUNT - 1 : 0];

    generate for(genvar i = 0; i < `REG_COUNT; i = i + 1) begin : get_res_flag_loop
        assign get_result_flag [i] = (MW_insn_is_F1 | MW_insn_is_F2) & MW_insn_dst == i;
    end
    endgenerate

    generate for(genvar i = 0; i < `REG_COUNT; i = i + 1) begin : reg_loop
        if(i == 0) begin
            always @(posedge clk)
                if(reset_RF)
                    r[i] <= 0;
                else if(init_R0)
                    r[i] <= init_R0_data;
                else
                    r[i] <= (get_result_flag[i]) ? W_result : r[i];
        end
        else begin
            always @(posedge clk)
                if(reset_RF)
                    r[i] <= 0;
                else
                    r[i] <= (get_result_flag[i]) ? W_result : r[i];
        end
    end
    endgenerate

    // debug
    wire [`REG_RANGE] R0 = r[0];
    wire [`REG_RANGE] R1 = r[1];
    wire [`REG_RANGE] R2 = r[2];
    wire [`REG_RANGE] R3 = r[3];
    wire [`REG_RANGE] R4 = r[4];
    wire [`REG_RANGE] R5 = r[5];
    wire [`REG_RANGE] R6 = r[6];
    wire [`REG_RANGE] R7 = r[7];
    wire [`REG_RANGE] R8 = r[8];
    wire [`REG_RANGE] R9 = r[9];
    wire [`REG_RANGE] R10 = r[10];
    wire [`REG_RANGE] R11 = r[11];
    wire [`REG_RANGE] R12 = r[12];
    wire [`REG_RANGE] R13 = r[13];
    wire [`REG_RANGE] R14 = r[14];
    wire [`REG_RANGE] R15 = r[15];

endmodule