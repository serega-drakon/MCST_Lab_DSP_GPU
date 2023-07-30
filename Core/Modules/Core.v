module Core (
    input wire clk,
    input wire reset,

    input wire init_R0_flag,
    input wire [REG_COUNT - 1 : 0] init_R0_,
    input wire [INSN_COUNT * INSN_SIZE - 1 : 0] insn_data_in,
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

    reg [REG_SIZE - 1 : 0] r [REG_COUNT - 1 : 0];

    reg [INSN_SIZE - 1 : 0] insn_mem [INSN_COUNT - 1 : 0];

    localparam INSN_PTR_SIZE = $clog2(INSN_COUNT);  // здесь указатель на всю инструкцию, а не конкретный байт, те
    reg [INSN_PTR_SIZE - 1 : 0] insn_ptr;            // без нуля в младшем бите
    reg [INSN_PTR_SIZE - 1 : 0] FD_insn_ptr;
    reg [INSN_PTR_SIZE - 1 : 0] DX_insn_ptr;

    reg [INSN_SIZE - 1 : 0] insn_data [INSN_COUNT - 1 : 0];
    reg [INSN_SIZE - 1 : 0] FD_insn;

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else
            Ready <= (Start & Ready) ? 0 : Ready; // FIXME

    always @(posedge clk)
        if(reset)
            insn_ptr <= 0;
        else
            insn_ptr <= (Start & Ready) ? 0 : insn_ptr; // FIXME

    always @(posedge clk)
        if(~reset)
            FD_insn_ptr <= (~Ready) ? insn_ptr : FD_insn_ptr;

    always @(posedge clk)
        if(~reset)
            DX_insn_ptr <= (~Ready) ? FD_insn_ptr : DX_insn_ptr;




endmodule