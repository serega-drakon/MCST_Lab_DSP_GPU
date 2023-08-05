`include "Inc/Instruction Set.def.v"
`include "Inc/Constants.def.v"
`include "RegisterFile.v"
`include "InsnMemory.v"
`include "ALU.v"

module Core #(
    parameter CORE_ID = 0,

    parameter INSN_COUNT = `INSN_COUNT,
    parameter INSN_SIZE = `INSN_SIZE,
    parameter INSN_OPC_SIZE = `INSN_OPC_SIZE,
    parameter INSN_OPC_OFFSET = 12,
    parameter INSN_SRC_0_SIZE = `REG_PTR_SIZE,
    parameter INSN_SRC_0_OFFSET = 8,
    parameter INSN_SRC_1_SIZE = `REG_PTR_SIZE,
    parameter INSN_SRC_1_OFFSET = 4,
    parameter INSN_SRC_2_SIZE = `REG_PTR_SIZE,
    parameter INSN_SRC_2_OFFSET = 0,
    parameter INSN_DST_SIZE = `REG_PTR_SIZE,
    parameter INSN_DST_OFFSET = 0,
    parameter INSN_CONST_SIZE = `REG_SIZE,
    parameter INSN_CONST_OFFSET = 0,
    parameter INSN_TARGET_SIZE = `INSN_PTR_SIZE,
    parameter INSN_TARGET_OFFSET = 4,
    parameter ADDR_SIZE = `ADDR_SIZE,
    parameter REG_COUNT = `REG_COUNT,
    parameter REG_SIZE = `REG_SIZE,
    parameter INSN_PTR_SIZE = `INSN_PTR_SIZE,  // здесь указатель на всю инструкцию, а не конкретный байт, те
    parameter CORE_ID_SIZE = `CORE_ID_SIZE  // без нуля в младшем бите
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
    output wire [1 : 0] enable
    );

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

    wire [INSN_OPC_SIZE - 1 : 0] curr_insn_opc = insn_opc(curr_insn);
    wire [INSN_OPC_SIZE - 1 : 0] FD_insn_opc = insn_opc(FD_insn_reg);  //для удобства
    wire [INSN_OPC_SIZE - 1 : 0] DX_insn_opc = insn_opc(DX_insn_reg);
    wire [INSN_OPC_SIZE - 1 : 0] XM_insn_opc = insn_opc(XM_insn_reg);
    wire [INSN_OPC_SIZE - 1 : 0] MW_insn_opc = insn_opc(MW_insn_reg);

    wire [INSN_SRC_0_SIZE - 1 : 0] curr_insn_src_0 = insn_src_0(curr_insn);
    wire [INSN_SRC_0_SIZE - 1 : 0] FD_insn_src_0 = insn_src_0(FD_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] DX_insn_src_0 = insn_src_0(DX_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] XM_insn_src_0 = insn_src_0(XM_insn_reg);
    wire [INSN_SRC_0_SIZE - 1 : 0] MW_insn_src_0 = insn_src_0(MW_insn_reg);

    wire [INSN_SRC_1_SIZE - 1 : 0] curr_insn_src_1 = insn_src_1(curr_insn);
    wire [INSN_SRC_1_SIZE - 1 : 0] FD_insn_src_1 = insn_src_1(FD_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] DX_insn_src_1 = insn_src_1(DX_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] XM_insn_src_1 = insn_src_1(XM_insn_reg);
    wire [INSN_SRC_1_SIZE - 1 : 0] MW_insn_src_1 = insn_src_1(MW_insn_reg);

    wire [INSN_SRC_2_SIZE - 1 : 0] curr_insn_src_2 = insn_src_2(curr_insn);
    wire [INSN_SRC_2_SIZE - 1 : 0] FD_insn_src_2 = insn_src_2(FD_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] DX_insn_src_2 = insn_src_2(DX_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] XM_insn_src_2 = insn_src_2(XM_insn_reg);
    wire [INSN_SRC_2_SIZE - 1 : 0] MW_insn_src_2 = insn_src_2(MW_insn_reg);

    wire [INSN_DST_SIZE - 1 : 0] curr_insn_dst = insn_dst(curr_insn);
    wire [INSN_DST_SIZE - 1 : 0] FD_insn_dst = insn_dst(FD_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] DX_insn_dst = insn_dst(DX_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] XM_insn_dst = insn_dst(XM_insn_reg);
    wire [INSN_DST_SIZE - 1 : 0] MW_insn_dst = insn_dst(MW_insn_reg);

    wire [INSN_CONST_SIZE - 1 : 0] curr_insn_const = insn_const(curr_insn);
    wire [INSN_CONST_SIZE - 1 : 0] FD_insn_const = insn_const(FD_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] DX_insn_const = insn_const(DX_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] XM_insn_const = insn_const(XM_insn_reg);
    wire [INSN_CONST_SIZE - 1 : 0] MW_insn_const = insn_const(MW_insn_reg);

    wire [INSN_TARGET_SIZE - 1 : 0] curr_insn_target = insn_target(curr_insn);
    wire [INSN_TARGET_SIZE - 1 : 0] FD_insn_target = insn_target(FD_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] DX_insn_target = insn_target(DX_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] XM_insn_target = insn_target(XM_insn_reg);
    wire [INSN_TARGET_SIZE - 1 : 0] MW_insn_target = insn_target(MW_insn_reg);

    function insn_is_F0; // а это - инструкции без аргументов
        input [INSN_OPC_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F0 = (insn_ops == `NOP | insn_ops == `READY);
        end
    endfunction

    function insn_is_F1;
        input [INSN_OPC_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F1 = (insn_ops == `ADD | insn_ops == `SUB | insn_ops == `MUL
                | insn_ops == `DIV | insn_ops == `CMPGE | insn_ops == `RSHIFT | insn_ops == `LSHIFT
                | insn_ops == `AND | insn_ops == `OR | insn_ops == `XOR | insn_ops == `LD);
        end
    endfunction

    function insn_is_F2;
        input [INSN_OPC_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F2 = (insn_ops == `SET_CONST);
        end
    endfunction

    function insn_is_F3;
        input [INSN_OPC_SIZE - 1 : 0] insn_ops;
        begin
            insn_is_F3 = (insn_ops == `ST);
        end
    endfunction

    function insn_is_F4;
        input [INSN_OPC_SIZE - 1 : 0] insn_ops;
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

    reg [INSN_PTR_SIZE - 1 : 0] insn_ptr_r;
    reg [INSN_PTR_SIZE - 1 : 0] FD_insn_ptr_r; //FIXME: они точно нужны?
    reg [INSN_PTR_SIZE - 1 : 0] DX_insn_ptr_r;

    //случай с st учтен под байпасом
    wire stall = (DX_insn_opc == `READY)
        | (DX_insn_opc == `LD) & (((FD_insn_is_F1 | FD_insn_is_F4) & DX_insn_dst == FD_insn_src_0) |
        FD_insn_is_F1 & DX_insn_dst == FD_insn_src_1);

    wire [REG_SIZE - 1 : 0] W_result;
    wire init_R0 = Start & Ready & init_R0_flag;
    wire [REG_SIZE - 1 : 0] D_src_0_data;
    wire [REG_SIZE - 1 : 0] D_src_1_data;
    wire [REG_SIZE - 1 : 0] D_src_2_data;

    reg [REG_SIZE - 1 : 0] DX_src_0_data_r;
    reg [REG_SIZE - 1 : 0] DX_src_1_data_r;
    reg [REG_SIZE - 1 : 0] DX_src_2_data_r;

    wire reset_RF = reset;

    RegisterFile RegisterFile(.reset_RF(reset_RF), .clk(clk), .init_R0(init_R0), .init_R0_data(init_R0_data),
        .W_result(W_result), .FD_insn_src_0(FD_insn_src_0), .FD_insn_src_1(FD_insn_src_1),
        .FD_insn_src_2(FD_insn_src_2), .MW_insn_dst(MW_insn_dst), .MW_insn_src_0(MW_insn_src_0),
        .MW_insn_is_F1(MW_insn_is_F1), .MW_insn_is_F2(MW_insn_is_F2), .D_src_0_data(D_src_0_data),
        .D_src_1_data(D_src_1_data), .D_src_2_data(D_src_2_data));

    wire init_insn_mem = Start & Ready;
    wire [INSN_SIZE - 1 : 0] curr_insn;

    InsnMemory InsnMemory(.clk(clk), .reset(reset), .init_insn_mem(init_insn_mem), .insn_data(insn_data),
        .insn_ptr(insn_ptr_r), .insn_curr(curr_insn));

    //это байпасы пошли
    wire [REG_SIZE - 1 : 0] X_src_0_data =  //случай с ld вырезан с помошью stall
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_0 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_0) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_0 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_0) ?
        W_result :DX_src_0_data_r;
    wire [REG_SIZE - 1 : 0] X_src_1_data =
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_1 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_1) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_1 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_1) ?
        W_result :DX_src_1_data_r;
    wire [REG_SIZE - 1 : 0] X_src_2_data =
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_2 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_2) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_2 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_2) ?
        W_result :DX_src_2_data_r;

    wire [REG_SIZE - 1 : 0] src_0_data_ALU = X_src_0_data;
    wire [REG_SIZE - 1 : 0] src_1_data_ALU = X_src_1_data;
    wire [REG_SIZE - 1 : 0] X_result_ALU;
    wire X_branch_cond_ALU;

    ALU ALU(.src_0_data_ALU(src_0_data_ALU), .src_1_data_ALU(src_1_data_ALU), .DX_insn_opc(DX_insn_opc),
        .X_result_ALU(X_result_ALU), .X_branch_cond_ALU(X_branch_cond_ALU));

    wire X_branch_cond = X_branch_cond_ALU & DX_insn_is_F4; //под F4 только переходы

    reg [REG_SIZE - 1 : 0] XM_O_data_r;
    reg [REG_SIZE - 1 : 0] XM_B_data_r;
    reg [REG_SIZE - 1 : 0] XM_C_data_r;

    wire [REG_SIZE - 1 : 0] X_O_data = (DX_insn_opc == `ST | DX_insn_opc == `LD) ? X_src_0_data :
        (~DX_insn_is_F2) ? X_result_ALU :
        ((DX_insn_src_0 == 0) ? {{(REG_SIZE - CORE_ID_SIZE){1'b0}}, CORE_ID[CORE_ID_SIZE - 1 : 0]}
        : MW_insn_const);
    wire [REG_SIZE - 1 : 0] X_B_data = X_src_1_data;
    wire [REG_SIZE - 1 : 0] X_C_data = X_src_2_data;
    //addr = {XM_src_ld_st_data, XM_src_O_data}

    reg [REG_SIZE - 1 : 0] MW_O_data_r;
    reg [REG_SIZE - 1 : 0] MW_D_data_r;
    wire [REG_SIZE - 1 : 0] M_O_data;
    wire [REG_SIZE - 1 : 0] M_D_data;

    wire [REG_SIZE - 1 : 0] M_B_data;
    wire [REG_SIZE - 1 : 0] M_C_data;

    // если ld в W а st в M
    assign M_O_data = (MW_insn_opc == `LD & (XM_insn_opc == `ST | XM_insn_opc == `LD) & MW_insn_dst == XM_insn_src_0) ?
        MW_D_data_r:XM_O_data_r;
    assign M_B_data = (MW_insn_opc == `LD & (XM_insn_opc == `ST | XM_insn_opc == `LD) & MW_insn_dst == XM_insn_src_1) ?
        MW_D_data_r:XM_B_data_r;
    assign M_C_data = (MW_insn_opc == `LD & (XM_insn_opc == `ST ) & MW_insn_dst == XM_insn_src_2) ?
        MW_D_data_r:XM_C_data_r;
    assign M_D_data = rd_data;

    assign addr[ADDR_SIZE - 1 : 0] =
        {M_B_data[CORE_ID_SIZE - 1 : 0], M_O_data [REG_SIZE - 1 : 0]};

    wire M_block = (XM_insn_opc == `LD | XM_insn_opc == `ST) & ~ready_sig;

    assign enable = {2 {XM_insn_opc == `LD}} & {2'b01}
                    | {2 {XM_insn_opc == `ST}} & {2'b10};

    assign wr_data = M_C_data;

    wire block_all_pipe = M_block | Ready;

    assign W_result = (MW_insn_opc == `LD) ? MW_D_data_r:MW_O_data_r;

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else if(Start & Ready)
            Ready <= 0;
        else
            Ready <= (MW_insn_opc == `READY) ? 1 : Ready; //хотя тут можно даже на X закончить

    always @(posedge clk)
        if(reset)
            insn_ptr_r <= 0;
        else if(Start & Ready)
            insn_ptr_r <= 0;
        else
            insn_ptr_r <= (stall | block_all_pipe) ? insn_ptr_r:
                (X_branch_cond) ? DX_insn_target : insn_ptr_r+ 1;

    always @(posedge clk)
        if(~reset)
            FD_insn_ptr_r <= (stall | block_all_pipe) ? FD_insn_ptr_r:insn_ptr_r;

    always @(posedge clk)
        if(~reset)
            DX_insn_ptr_r <= (stall | block_all_pipe) ? DX_insn_ptr_r:FD_insn_ptr_r;

    always @(posedge clk)
        if(reset | Start & Ready)
            FD_insn_reg <= `NOP;
        else
            FD_insn_reg <= (stall | block_all_pipe) ?  FD_insn_reg :
                (X_branch_cond) ? `NOP :
                (FD_insn_ptr_r == INSN_COUNT - 1) ? `READY : curr_insn;

    always @(posedge clk)
        if(reset)
            DX_insn_reg <= `NOP;
        else
            DX_insn_reg <= (block_all_pipe) ? DX_insn_reg :
                (stall | X_branch_cond) ? `NOP : FD_insn_reg;

    always @(posedge clk)
        if(reset)
            XM_insn_reg <= `NOP;
        else
            XM_insn_reg <= (block_all_pipe) ? XM_insn_reg : DX_insn_reg ;

    always @(posedge clk)
        if(reset)
            MW_insn_reg <= `NOP;
        else
            MW_insn_reg <= (block_all_pipe) ? MW_insn_reg : XM_insn_reg;

    always @(posedge clk)   //FIXME: энергоэффективность
        DX_src_0_data_r <= (block_all_pipe) ? DX_src_0_data_r: D_src_0_data;

    always @(posedge clk)
        DX_src_1_data_r <= (block_all_pipe) ? DX_src_1_data_r: D_src_1_data;

    always @(posedge clk)
        DX_src_2_data_r <= (block_all_pipe) ? DX_src_2_data_r: D_src_2_data;

    always @(posedge clk)
        XM_O_data_r <= (block_all_pipe) ? XM_O_data_r: X_O_data;

    always @(posedge clk)
        XM_B_data_r <= (block_all_pipe) ? XM_B_data_r: X_B_data;

    always @(posedge clk)
        XM_C_data_r <= (block_all_pipe) ? XM_C_data_r: X_C_data;

    always @(posedge clk)
        MW_O_data_r <= (block_all_pipe) ? MW_O_data_r: M_O_data;

    always @(posedge clk)
        MW_D_data_r <= (XM_insn_opc == `LD & ~block_all_pipe) ? M_D_data :MW_D_data_r;

endmodule