`include "Inc/Instruction Set.vh"
`include "Inc/Constants.vh"
`include "RegisterFile.v"
`include "InsnMemory.v"
`include "ALU.v"

module Core #(
    parameter CORE_ID = 0
)(
    input wire clk,
    input wire reset,

    input wire init_R0_flag,
    input wire [REG_SIZE - 1 : 0] init_R0_data,
    input wire [INSN_COUNT * INSN_SIZE - 1 : 0] insn_data,
    input wire Start,
    output reg Ready,

    input wire [REG_SIZE - 1 : 0] rd_data,
    input wire ready_sig, // != Ready
    output wire [REG_SIZE - 1 : 0] wr_data,
    output wire [ADDR_SIZE - 1 : 0] addr,
    output reg [1 : 0] enable
    );

    localparam INSN_COUNT = `INSN_COUNT;
    localparam INSN_SIZE = `INSN_SIZE;
    localparam INSN_OPC_SIZE = `INSN_OPC_SIZE;
    localparam INSN_OPC_OFFSET = 12;
    localparam INSN_SRC_0_SIZE = `REG_PTR_SIZE;
    localparam INSN_SRC_0_OFFSET = 8;
    localparam INSN_SRC_1_SIZE = `REG_PTR_SIZE;
    localparam INSN_SRC_1_OFFSET = 4;
    localparam INSN_SRC_2_SIZE = `REG_PTR_SIZE;
    localparam INSN_SRC_2_OFFSET = 0;
    localparam INSN_DST_SIZE = `REG_PTR_SIZE;
    localparam INSN_DST_OFFSET = 0;
    localparam INSN_CONST_SIZE = `REG_SIZE;
    localparam INSN_CONST_OFFSET = 0;
    localparam INSN_TARGET_SIZE = `INSN_PTR_SIZE;
    localparam INSN_TARGET_OFFSET = 4;
    localparam ADDR_SIZE = `ADDR_SIZE;
    localparam REG_COUNT = `REG_COUNT ;
    localparam REG_SIZE = `REG_SIZE;
    localparam INSN_PTR_SIZE = `INSN_PTR_SIZE;  // здесь указатель на всю инструкцию, а не конкретный байт, те
    localparam CORE_ID_PTR_SIZE = 4;            // без нуля в младшем бите

    reg [INSN_SIZE - 1 : 0] FD_insn_reg;
    reg [INSN_SIZE - 1 : 0] DX_insn_reg;
    reg [INSN_SIZE - 1 : 0] XM_insn_reg;
    reg [INSN_SIZE - 1 : 0] MW_insn_reg;

    function [INSN_OPC_SIZE- 1 : 0] insn_opc;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_opc = insn_reg[INSN_OPC_SIZE+INSN_OPC_OFFSET:INSN_OPC_OFFSET];
        end
    endfunction

    function [INSN_OPC_SIZE- 1 : 0] insn_src_0;
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

    function [INSN_TARGET_SIZE - 1 : 0] insn_target;
        input [INSN_SIZE - 1 : 0] insn_reg;
        begin
            insn_target = insn_reg[INSN_TARGET_SIZE + INSN_TARGET_OFFSET : INSN_TARGET_OFFSET];
        end
    endfunction // это должно синтезироваться в провод

    wire [INSN_OPC_SIZE- 1 : 0] FD_insn_opc = insn_opc(FD_insn_reg);  //для удобства
    wire [INSN_OPC_SIZE- 1 : 0] DX_insn_opc = insn_opc(DX_insn_reg);
    wire [INSN_OPC_SIZE- 1 : 0] XM_insn_opc = insn_opc(XM_insn_reg);
    wire [INSN_OPC_SIZE- 1 : 0] MW_insn_opc = insn_opc(MW_insn_reg);

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

    wire [INSN_TARGET_SIZE - 1 : 0] FD_insn_target = insn_target(FD_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] DX_insn_target = insn_target(DX_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] XM_insn_target = insn_target(XM_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] MW_insn_target = insn_target(MW_insn_reg);

    function insn_is_F0; // а это - инструкции без аргументов
        input [INSN_OPC_SIZE- 1 : 0] insn_ops;
        begin
            insn_is_F0 = (insn_ops == `NOP | insn_ops == `READY);
        end
    endfunction

    function insn_is_F1;
        input [INSN_OPC_SIZE- 1 : 0] insn_ops;
        begin
            insn_is_F1 = (insn_ops == `ADD | insn_ops == `SUB | insn_ops == `MUL
                | insn_ops == `DIV | insn_ops == `CMPGE | insn_ops == `RSHIFT | insn_ops == `LSHIFT
                | insn_ops == `AND | insn_ops == `OR | insn_ops == `XOR | insn_ops == `LD);
        end
    endfunction

    function insn_is_F2;
        input [INSN_OPC_SIZE- 1 : 0] insn_ops;
        begin
            insn_is_F2 = (insn_ops == `SET_CONST);
        end
    endfunction

    function insn_is_F3;
        input [INSN_OPC_SIZE- 1 : 0] insn_ops;
        begin
            insn_is_F3 = (insn_ops == `ST);
        end
    endfunction

    function insn_is_F4;
        input [INSN_OPC_SIZE- 1 : 0] insn_ops;
        begin
            insn_is_F4 = (insn_ops == `BNZ);
        end
    endfunction

    wire FD_insn_is_F0 = insn_is_F0(FD_insn_opc);
    wire DX_insn_is_F0 = insn_is_F0(DX_insn_opc);
    wire XM_insn_is_F0 = insn_is_F0(XM_insn_opc);
    wire MW_insn_is_F0 = insn_is_F0(MW_insn_opc);

    wire FD_insn_is_F1 = insn_is_F1(FD_insn_opc);
    wire DX_insn_is_F1 = insn_is_F1(DX_insn_opc);
    wire XM_insn_is_F1 = insn_is_F1(XM_insn_opc);
    wire MW_insn_is_F1 = insn_is_F1(MW_insn_opc);

    wire FD_insn_is_F2 = insn_is_F2(FD_insn_opc);
    wire DX_insn_is_F2 = insn_is_F2(DX_insn_opc);
    wire XM_insn_is_F2 = insn_is_F2(XM_insn_opc);
    wire MW_insn_is_F2 = insn_is_F2(MW_insn_opc);

    wire FD_insn_is_F3 = insn_is_F3(FD_insn_opc);
    wire DX_insn_is_F3 = insn_is_F3(DX_insn_opc);
    wire XM_insn_is_F3 = insn_is_F3(XM_insn_opc);
    wire MW_insn_is_F3 = insn_is_F3(MW_insn_opc);

    wire FD_insn_is_F4 = insn_is_F4(FD_insn_opc);
    wire DX_insn_is_F4 = insn_is_F4(DX_insn_opc);
    wire XM_insn_is_F4 = insn_is_F4(XM_insn_opc);
    wire MW_insn_is_F4 = insn_is_F4(MW_insn_opc);

    reg [INSN_PTR_SIZE - 1 : 0] insn_ptr;
    reg [INSN_PTR_SIZE - 1 : 0] FD_insn_ptr; //FIXME: они точно нужны?
    reg [INSN_PTR_SIZE - 1 : 0] DX_insn_ptr;

    reg block; // при включенном block: IP <= IP, fd_insn <= fd_insn, dx_insn <= nop

    wire stall;
    assign stall = block; //FIXME

    //FIXME: memory part

    wire [REG_SIZE - 1 : 0] W_result;
    wire init_R0 = Start & Ready & init_R0_flag;
    wire [REG_SIZE - 1 : 0] D_src_0_data;
    wire [REG_SIZE - 1 : 0] D_src_1_data; //FIXME: assign

    reg [REG_SIZE - 1 : 0] DX_src_0_data;
    reg [REG_SIZE - 1 : 0] DX_src_1_data; //FIXME: logic

    //FIXME: XM_res!! + ld/st branch

    wire reset_RF = reset | (Start & Ready);

    RegisterFile RegisterFile(.reset_RF(reset_RF), .clk(clk), .init_R0(init_R0), .init_R0_data(init_R0_data),
        .W_result(W_result), .FD_insn_src_0(FD_insn_src_0), .FD_insn_src_1(FD_insn_src_1), .MW_insn_dst(MW_insn_dst),
        .MW_insn_src_0(MW_insn_src_0), .MW_insn_is_F1(MW_insn_is_F1), .MW_insn_is_F2(MW_insn_is_F2),
        .D_src_0_data(D_src_0_data), .D_src_1_data(D_src_1_data));

    wire init_insn_mem = Start & Ready;
    wire insn_curr;

    InsnMemory InsnMemory(.clk(clk), .reset(reset), .init_insn_mem(init_insn_mem), .insn_data(insn_data),
        .insn_ptr(insn_ptr), .insn_curr(insn_curr));

    wire [REG_SIZE - 1 : 0] src_0_data_ALU = DX_src_0_data; //FIXME: bypass
    wire [REG_SIZE - 1 : 0] src_1_data_ALU = DX_src_1_data;
    wire [REG_SIZE - 1 : 0] X_result_ALU;
    wire X_branch_cond_ALU;

    ALU ALU(.src_0_data_ALU(src_0_data_ALU), .src_1_data_ALU(src_1_data_ALU), .DX_insn_opc(DX_insn_opc),
        .X_result_ALU(X_result_ALU), .X_branch_cond_ALU(X_branch_cond_ALU));

    wire X_branch_cond = X_branch_cond_ALU & DX_insn_is_F4; //под F4 только переходы

    reg [REG_SIZE - 1 : 0] XM_src_A_data; //тут порядок перемешан
    reg [REG_SIZE - 1 : 0] XM_src_B_data;
    reg [CORE_ID_PTR_SIZE - 1 : 0] XM_src_ld_st_data;

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else if(Start & Ready)
            Ready <= 0;
        else
            Ready <= (MW_insn_opc == `READY) ? 1 : Ready;

    always @(posedge clk)
        if(reset)
            block <= 1;
        else if(Start & Ready)
            block <= 0;
        else
            block <= (FD_insn_opc == `READY) ? 1 : block;

    always @(posedge clk)
        if(reset)
            insn_ptr <= 0;
        else if(Start & Ready)
            insn_ptr <= 0;
        else
            insn_ptr <= (stall) ? insn_ptr : (X_branch_cond) ? DX_insn_target : insn_ptr + 1;

    always @(posedge clk)
        if(~reset)
            FD_insn_ptr <= insn_ptr;

    always @(posedge clk)
        if(~reset)
            DX_insn_ptr <= FD_insn_ptr;

    always @(posedge clk)
        if(reset | Start & Ready)
            FD_insn_reg <= `NOP;
        else
            FD_insn_reg <= (stall) ?  FD_insn_reg :
                (X_branch_cond) ? `NOP :
                (FD_insn_ptr == INSN_COUNT - 1) ? `READY : insn_curr;

    always @(posedge clk)
        if(reset)
            DX_insn_reg <= `NOP;
        else
            DX_insn_reg <= (stall) ? `NOP :
                (X_branch_cond) ? `NOP : FD_insn_reg;

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

    always @(posedge clk)
        DX_src_0_data <= D_src_0_data;

    always @(posedge clk)
        DX_src_1_data <= D_src_1_data;

    always @(posedge clk)
        XM_src_A_data <= (DX_insn_opc == `ST | DX_insn_opc == `LD) ?  :  ;

endmodule