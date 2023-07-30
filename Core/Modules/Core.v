`include "Instruction Set.vh"

module Core (
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
    assign stall = block;

    wire branch_cond;

    wire [INSN_OPS_SIZE - 1 : 0] FD_insn_ops;  //для удобства
    wire [INSN_OPS_SIZE - 1 : 0] DX_insn_ops;
    wire [INSN_OPS_SIZE - 1 : 0] XM_insn_ops;
    wire [INSN_OPS_SIZE - 1 : 0] MW_insn_ops;

    wire [INSN_SRC_0_SIZE - 1 : 0] FD_insn_src_0;
    wire [INSN_SRC_0_SIZE - 1 : 0] DX_insn_src_0;
    wire [INSN_SRC_0_SIZE - 1 : 0] XM_insn_src_0;
    wire [INSN_SRC_0_SIZE - 1 : 0] MW_insn_src_0;

    wire [INSN_SRC_1_SIZE - 1 : 0] FD_insn_src_1;
    wire [INSN_SRC_1_SIZE - 1 : 0] DX_insn_src_1;
    wire [INSN_SRC_1_SIZE - 1 : 0] XM_insn_src_1;
    wire [INSN_SRC_1_SIZE - 1 : 0] MW_insn_src_1;

    wire [INSN_SRC_2_SIZE - 1 : 0] FD_insn_src_2;
    wire [INSN_SRC_2_SIZE - 1 : 0] DX_insn_src_2;
    wire [INSN_SRC_2_SIZE - 1 : 0] XM_insn_src_2;
    wire [INSN_SRC_2_SIZE - 1 : 0] MW_insn_src_2;

    wire [INSN_DST_SIZE - 1 : 0] FD_insn_dst;
    wire [INSN_DST_SIZE - 1 : 0] DX_insn_dst;
    wire [INSN_DST_SIZE - 1 : 0] XM_insn_dst;
    wire [INSN_DST_SIZE - 1 : 0] MW_insn_dst;

    wire [INSN_CONST_SIZE - 1 : 0] FD_insn_const;  // тупо семиэтажку возвел
    wire [INSN_CONST_SIZE - 1 : 0] DX_insn_const;
    wire [INSN_CONST_SIZE - 1 : 0] XM_insn_const;
    wire [INSN_CONST_SIZE - 1 : 0] MW_insn_const;

    assign FD_insn_ops = FD_insn_reg[INSN_OPS_SIZE + INSN_OPS_OFFSET : INSN_OPS_OFFSET];
    assign DX_insn_ops = DX_insn_reg[INSN_OPS_SIZE + INSN_OPS_OFFSET : INSN_OPS_OFFSET];
    assign XM_insn_ops = XM_insn_reg[INSN_OPS_SIZE + INSN_OPS_OFFSET : INSN_OPS_OFFSET];
    assign MW_insn_ops = MW_insn_reg[INSN_OPS_SIZE + INSN_OPS_OFFSET : INSN_OPS_OFFSET];

    assign FD_insn_src_0 = FD_insn_reg[INSN_SRC_0_SIZE + INSN_SRC_0_OFFSET : INSN_SRC_0_OFFSET];
    assign DX_insn_src_0 = DX_insn_reg[INSN_SRC_0_SIZE + INSN_SRC_0_OFFSET : INSN_SRC_0_OFFSET];
    assign XM_insn_src_0 = XM_insn_reg[INSN_SRC_0_SIZE + INSN_SRC_0_OFFSET : INSN_SRC_0_OFFSET];
    assign MW_insn_src_0 = MW_insn_reg[INSN_SRC_0_SIZE + INSN_SRC_0_OFFSET : INSN_SRC_0_OFFSET];

    assign MW_insn_src_1 = FD_insn_reg[INSN_SRC_1_SIZE + INSN_SRC_1_OFFSET : INSN_SRC_1_OFFSET];
    assign MW_insn_src_1 = DX_insn_reg[INSN_SRC_1_SIZE + INSN_SRC_1_OFFSET : INSN_SRC_1_OFFSET];
    assign MW_insn_src_1 = XM_insn_reg[INSN_SRC_1_SIZE + INSN_SRC_1_OFFSET : INSN_SRC_1_OFFSET];
    assign MW_insn_src_1 = MW_insn_reg[INSN_SRC_1_SIZE + INSN_SRC_1_OFFSET : INSN_SRC_1_OFFSET];

    assign MW_insn_src_2 = FD_insn_reg[INSN_SRC_2_SIZE + INSN_SRC_2_OFFSET : INSN_SRC_2_OFFSET];
    assign MW_insn_src_2 = DX_insn_reg[INSN_SRC_2_SIZE + INSN_SRC_2_OFFSET : INSN_SRC_2_OFFSET];
    assign MW_insn_src_2 = XM_insn_reg[INSN_SRC_2_SIZE + INSN_SRC_2_OFFSET : INSN_SRC_2_OFFSET];
    assign MW_insn_src_2 = MW_insn_reg[INSN_SRC_2_SIZE + INSN_SRC_2_OFFSET : INSN_SRC_2_OFFSET];

    assign FD_insn_dst = FD_insn_reg[INSN_DST_SIZE + INSN_DST_OFFSET : INSN_DST_OFFSET];
    assign DX_insn_dst = DX_insn_reg[INSN_DST_SIZE + INSN_DST_OFFSET : INSN_DST_OFFSET];
    assign XM_insn_dst = XM_insn_reg[INSN_DST_SIZE + INSN_DST_OFFSET : INSN_DST_OFFSET];
    assign MW_insn_dst = MW_insn_reg[INSN_DST_SIZE + INSN_DST_OFFSET : INSN_DST_OFFSET];

    assign FD_insn_const = FD_insn_reg[INSN_CONST_SIZE + INSN_CONST_OFFSET : INSN_CONST_OFFSET];  // больше многоэтажек!!!!!!!
    assign DX_insn_const = DX_insn_reg[INSN_CONST_SIZE + INSN_CONST_OFFSET : INSN_CONST_OFFSET];
    assign XM_insn_const = XM_insn_reg[INSN_CONST_SIZE + INSN_CONST_OFFSET : INSN_CONST_OFFSET];
    assign MW_insn_const = MW_insn_reg[INSN_CONST_SIZE + INSN_CONST_OFFSET : INSN_CONST_OFFSET];

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else if(Start & Ready)
            Ready <= 0;
        else
            Ready <= (MW_insn_ops == `READY) ? 1 : Ready;

    always @(posedge clk) //пока не сделаю нормальный модуль stall будет это
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