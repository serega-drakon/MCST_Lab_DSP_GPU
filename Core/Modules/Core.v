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

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else
            Ready <= (Start & Ready) ? 0 :
                (~Ready & MW_insn_reg[15 : 12] == `READY) ? 1 : Ready;

    always @(posedge clk)
        if(reset)
            block <= 1;
        else
            block <= (Start & Ready) ? 0 :
                (DX_insn_reg[15 : 12] != `NOP) ? 1 :
                (MW_insn_reg[15 : 12] != `NOP) ? 0 : block;

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
        else
            insn_ptr <= (Start & Ready) ? 0 :
                (~stall) ? insn_ptr + 1 : insn_ptr;

    always @(posedge clk)
        if(~reset)
            FD_insn_ptr <= (~Ready) ? insn_ptr : FD_insn_ptr;

    always @(posedge clk)
        if(~reset)
            DX_insn_ptr <= (~Ready) ? FD_insn_ptr : DX_insn_ptr;

    always @(posedge clk)
        if(reset)
            FD_insn_reg <= `NOP;
        else
            FD_insn_reg <= (~Ready & insn_ptr != (INSN_COUNT - 1) & insn_mem[insn_ptr][15 : 12] != `BNZ) ? insn_mem[insn_ptr] :
                (Ready) ? `NOP : `READY;

    always @(posedge clk)
        if(reset)
            DX_insn_reg <= `NOP;
        else
            DX_insn_reg <= FD_insn_reg;

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