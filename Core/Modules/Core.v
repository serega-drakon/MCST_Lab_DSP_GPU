`include "Instruction Set.vh"

module Core #(
    parameter CORE_NUM = 0
)(
    input wire clk,
    input wire reset,

    input wire init_R0_flag,
    input wire [REG_COUNT - 1 : 0] init_R0_,
    input wire [INSN_COUNT * INSN_SIZE - 1 : 0] insn_data,
    input wire Start,
    output reg Ready,

    input wire [REG_SIZE - 1 : 0] rd_data,
    input wire val,
    output wire [REG_SIZE - 1 : 0] wr_data,
    output wire [ADDR_SIZE - 1 : 0] addr,
    output reg [1 : 0] enable
    );

    localparam INSN_COUNT = 16;
    localparam INSN_SIZE = 16;
    localparam INSN_OPS_SIZE = 4;
    localparam INSN_OPS_OFFSET = 12;
    localparam INSN_SRC_0_SIZE = 4;
    localparam INSN_SRC_0_OFFSET = 8;
    localparam INSN_SRC_1_SIZE = 4;
    localparam INSN_SRC_1_OFFSET = 4;
    localparam INSN_SRC_2_SIZE = 4;
    localparam INSN_SRC_2_OFFSET = 0;
    localparam INSN_DST_SIZE = 4;
    localparam INSN_DST_OFFSET = 0;
    localparam INSN_CONST_SIZE = 8;
    localparam INSN_CONST_OFFSET = 0;
    localparam ADDR_SIZE = 12;
    localparam REG_COUNT = 16;
    localparam REG_SIZE = 8;
    localparam INSN_PTR_SIZE = 4;   // здесь указатель на всю инструкцию, а не конкретный байт, те
                                    // без нуля в младшем бите
    reg [REG_SIZE - 1 : 0] r [REG_COUNT - 1 : 0];

    reg [INSN_SIZE - 1 : 0] insn_mem [INSN_COUNT - 1 : 0];

    reg [INSN_SIZE - 1 : 0] FD_insn_reg;
    reg [INSN_SIZE - 1 : 0] DX_insn_reg;
    reg [INSN_SIZE - 1 : 0] XM_insn_reg;
    reg [INSN_SIZE - 1 : 0] MW_insn_reg;

    reg [INSN_PTR_SIZE - 1 : 0] insn_ptr;
    reg [INSN_PTR_SIZE - 1 : 0] FD_insn_ptr;
    reg [INSN_PTR_SIZE - 1 : 0] DX_insn_ptr;

    reg block; // при включенном block: IP <= IP, fd_insn <= fd_insn, dx_insn <= nop

    wire stall;
    assign stall = block; //FIXME

    wire branch_cond; //FIXME
    assign branch_cond = 0;

    //FIXME: memory part

    function [INSN_OPS_SIZE - 1 : 0] insn_ops;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_ops = insn_reg[INSN_OPS_SIZE + INSN_OPS_OFFSET : INSN_OPS_OFFSET];
        end
    endfunction

    function [INSN_OPS_SIZE - 1 : 0] insn_src_0;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_src_0 = insn_reg[INSN_SRC_0_SIZE + INSN_SRC_0_OFFSET : INSN_SRC_0_OFFSET];
        end
    endfunction

    function [INSN_SRC_1_SIZE - 1 : 0] insn_src_1;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_src_1 = insn_reg[INSN_SRC_1_SIZE + INSN_SRC_1_OFFSET : INSN_SRC_1_OFFSET];
        end
    endfunction

    function [INSN_SRC_2_SIZE - 1 : 0] insn_src_2;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_src_2 = insn_reg[INSN_SRC_2_SIZE + INSN_SRC_2_OFFSET : INSN_SRC_2_OFFSET];
        end
    endfunction

    function [INSN_DST_SIZE - 1 : 0] insn_dst;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_dst = insn_reg[INSN_DST_SIZE + INSN_DST_OFFSET : INSN_DST_OFFSET];
        end
    endfunction

    function [INSN_CONST_SIZE - 1 : 0] insn_const;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_const = insn_reg[INSN_CONST_SIZE + INSN_CONST_OFFSET : INSN_CONST_OFFSET];
        end
    endfunction

    wire [INSN_OPS_SIZE - 1 : 0] FD_insn_ops = insn_ops(FD_insn_reg);  //для удобства
    wire [INSN_OPS_SIZE - 1 : 0] DX_insn_ops = insn_ops(DX_insn_reg);
    wire [INSN_OPS_SIZE - 1 : 0] XM_insn_ops = insn_ops(XM_insn_reg);
    wire [INSN_OPS_SIZE - 1 : 0] MW_insn_ops = insn_ops(MW_insn_reg);

    wire [INSN_SRC_0_SIZE - 1 : 0] FD_insn_src_0 = insn_src_0(FD_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] DX_insn_src_0 = insn_src_0(DX_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] XM_insn_src_0 = insn_src_0(XM_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] MW_insn_src_0 = insn_src_0(MW_insn_reg);

    wire [INSN_SRC_1_SIZE - 1 : 0] FD_insn_src_1 = insn_src_1(FD_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] DX_insn_src_1 = insn_src_1(DX_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] XM_insn_src_1 = insn_src_1(XM_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] MW_insn_src_1 = insn_src_1(MW_insn_reg);

    wire [INSN_SRC_2_SIZE - 1 : 0] FD_insn_src_2 = insn_src_2(FD_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] DX_insn_src_2 = insn_src_2(DX_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] XM_insn_src_2 = insn_src_2(XM_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] MW_insn_src_2 = insn_src_2(MW_insn_reg);

    wire [INSN_DST_SIZE - 1 : 0] FD_insn_dst = insn_dst(FD_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] DX_insn_dst = insn_dst(DX_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] XM_insn_dst = insn_dst(XM_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] MW_insn_dst = insn_dst(MW_insn_reg);

    wire [INSN_CONST_SIZE - 1 : 0] FD_insn_const = insn_const(FD_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] DX_insn_const = insn_const(DX_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] XM_insn_const = insn_const(XM_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] MW_insn_const = insn_const(MW_insn_reg);

    function insn_is_F1;
        input [INSN_OPS_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F1 = (insn_ops == `ADD | insn_ops == `SUB | insn_ops == `MUL
                | insn_ops == `DIV | insn_ops == `CMPGE | insn_ops == `RSHIFT | insn_ops == `LSHIFT
                | insn_ops == `AND | insn_ops == `OR | insn_ops == `XOR | insn_ops == `LD);
        end
    endfunction // это должно синтезироваться в провод

    function insn_is_F2;
        input [INSN_OPS_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F2 = (insn_ops == `SET_CONST);
        end
    endfunction

    function insn_is_F3;
        input [INSN_OPS_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F3 = (insn_ops == `ST);
        end
    endfunction

    function insn_is_F4;
        input [INSN_OPS_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F4 = (insn_ops == `BNZ | insn_ops == `READY);
        end
    endfunction

    wire FD_insn_is_F1 = insn_is_F1(FD_insn_ops);
    wire DX_insn_is_F1 = insn_is_F1(DX_insn_ops);
    wire XM_insn_is_F1 = insn_is_F1(XM_insn_ops);
    wire MW_insn_is_F1 = insn_is_F1(MW_insn_ops);

    wire FD_insn_is_F2 = insn_is_F2(FD_insn_ops);
    wire DX_insn_is_F2 = insn_is_F2(DX_insn_ops);
    wire XM_insn_is_F2 = insn_is_F2(XM_insn_ops);
    wire MW_insn_is_F2 = insn_is_F2(MW_insn_ops);

    wire FD_insn_is_F3 = insn_is_F3(FD_insn_ops);
    wire DX_insn_is_F3 = insn_is_F3(DX_insn_ops);
    wire XM_insn_is_F3 = insn_is_F3(XM_insn_ops);
    wire MW_insn_is_F3 = insn_is_F3(MW_insn_ops);

    wire FD_insn_is_F4 = insn_is_F4(FD_insn_ops);
    wire DX_insn_is_F4 = insn_is_F4(DX_insn_ops);
    wire XM_insn_is_F4 = insn_is_F4(XM_insn_ops);
    wire MW_insn_is_F4 = insn_is_F4(MW_insn_ops);

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else if(Start & Ready)
            Ready <= 0;
        else
            Ready <= (MW_insn_ops == `READY) ? 1 : Ready;

    always @(posedge clk)
        if(reset)
            block <= 1;
        else if(Start & Ready)
            block <= 0;
        else
            block <= (FD_insn_ops == `READY) ? 1 : block;

    generate for(genvar i = 0; i < INSN_COUNT; i = i + 1)
        always @(posedge clk)
            if(~reset)
                insn_mem[i][INSN_SIZE - 1 : 0] = (Start & Ready) ?
                    insn_data[(i + 1) * INSN_SIZE - 1 : i * INSN_SIZE] :
                    insn_mem[i][INSN_SIZE - 1 : 0];
    endgenerate

    always @(posedge clk)
        if(reset)
            insn_ptr <= 0;
        else if(Start & Ready)
            insn_ptr <= 0;
        else
            insn_ptr <= (~stall) ? insn_ptr + 1 : insn_ptr;

    generate for(genvar i = 0; i < REG_COUNT; i = i + 1)
        always @(posedge clk)
            if(reset)
                r[i] <= 0;
            else
                r[i] <= 0; //FIXME
    endgenerate

    always @(posedge clk)
        if(~reset)
            FD_insn_ptr <= insn_ptr;

    always @(posedge clk)
        if(~reset)
            DX_insn_ptr <= FD_insn_ptr;

    always @(posedge clk)
        if(reset)
            FD_insn_reg <= `NOP;
        else if(Start & Ready)
            FD_insn_reg <= `NOP;
        else
            FD_insn_reg <= (stall) ?  FD_insn_reg :
                (branch_cond) ? `NOP :
                (FD_insn_ptr == INSN_COUNT - 1) ? `READY : insn_mem[insn_ptr];

    always @(posedge clk)
        if(reset)
            DX_insn_reg <= `NOP;
        else
            DX_insn_reg <= (stall) ? `NOP :
                (branch_cond) ? `NOP : FD_insn_reg;

    always @(posedge clk)
        if(reset)
            XM_insn_reg <= `NOP;
        else
            XM_insn_reg <= DX_insn_reg;

    always @(posedge clk)
        if(reset)
            MW_insn_reg <= `NOP;
        else
            MW_insn_reg <= XM_insn_reg;

endmodule