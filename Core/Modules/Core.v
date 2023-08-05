`include "Inc/Instruction Set.def.v"
`include "Inc/Constants.def.v"
`include "RegisterFile.v"
`include "InsnMemory.v"
`include "ALU.v"

module Core #(
    parameter CORE_ID = 0
)(
    input wire clk,
    input wire reset,

    input wire init_R0_flag,
    input wire [`REG_RANGE] init_R0_data,
    input wire [`INSN_BUS_RANGE] insn_data,
    input wire Start,
    output reg Ready,

    input wire [`REG_RANGE] rd_data_M,
    input wire ready_M, // != Ready
    output wire [`REG_RANGE] wr_data_M,
    output wire [`ADDR_RANGE] addr_M,
    output wire [1 : 0] enable_M
    );

    reg [`INSN_RANGE] FD_insn_reg;
    reg [`INSN_RANGE] DX_insn_reg;
    reg [`INSN_RANGE] XM_insn_reg;
    reg [`INSN_RANGE] MW_insn_reg;

    wire [`INSN_OPC_RANGE] curr_insn_opc = curr_insn [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE] FD_insn_opc = FD_insn_reg [`INSN_OPC_OFFSET_RANGE];  //для удобства
    wire [`INSN_OPC_RANGE] DX_insn_opc = DX_insn_reg [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE] XM_insn_opc = XM_insn_reg [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE] MW_insn_opc = MW_insn_reg [`INSN_OPC_OFFSET_RANGE];

    wire [`INSN_SRC_0_RANGE] curr_insn_src_0 = curr_insn [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE] FD_insn_src_0 = FD_insn_reg [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE] DX_insn_src_0 = DX_insn_reg [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE] XM_insn_src_0 = XM_insn_reg [`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE] MW_insn_src_0 = MW_insn_reg [`INSN_OPC_OFFSET_RANGE];

    wire [`INSN_SRC_1_RANGE] curr_insn_src_1 = curr_insn [`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE] FD_insn_src_1 = FD_insn_reg [`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE] DX_insn_src_1 = DX_insn_reg [`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE] XM_insn_src_1 = XM_insn_reg [`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE] MW_insn_src_1 = MW_insn_reg [`INSN_SRC_1_OFFSET_RANGE];

    wire [`INSN_SRC_2_RANGE] curr_insn_src_2 = curr_insn [`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE] FD_insn_src_2 = FD_insn_reg [`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE] DX_insn_src_2 = DX_insn_reg [`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE] XM_insn_src_2 = XM_insn_reg [`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE] MW_insn_src_2 = MW_insn_reg [`INSN_SRC_2_OFFSET_RANGE];

    wire [`INSN_DST_RANGE] curr_insn_dst = curr_insn [`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE] FD_insn_dst = FD_insn_reg [`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE] DX_insn_dst = DX_insn_reg [`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE] XM_insn_dst = XM_insn_reg [`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE] MW_insn_dst = MW_insn_reg [`INSN_DST_OFFSET_RANGE];

    wire [`INSN_CONST_RANGE] curr_insn_const = curr_insn [`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE] FD_insn_const = FD_insn_reg [`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE] DX_insn_const = DX_insn_reg [`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE] XM_insn_const = XM_insn_reg [`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE] MW_insn_const = MW_insn_reg [`INSN_CONST_OFFSET_RANGE];

    wire [`INSN_TARGET_RANGE] curr_insn_target = curr_insn [`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE] FD_insn_target = FD_insn_reg [`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE] DX_insn_target = DX_insn_reg [`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE] XM_insn_target = XM_insn_reg [`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE] MW_insn_target = MW_insn_reg [`INSN_TARGET_OFFSET_RANGE];

    function insn_is_F0; // а это - инструкции без аргументов
        input [`INSN_OPC_RANGE] insn_ops;
        begin
            insn_is_F0 = (insn_ops == `NOP | insn_ops == `READY);
        end
    endfunction

    function insn_is_F1;
        input [`INSN_OPC_RANGE] insn_ops;
        begin
            insn_is_F1 = (insn_ops == `ADD | insn_ops == `SUB | insn_ops == `MUL
                | insn_ops == `DIV | insn_ops == `CMPGE | insn_ops == `RSHIFT | insn_ops == `LSHIFT
                | insn_ops == `AND | insn_ops == `OR | insn_ops == `XOR | insn_ops == `LD);
        end
    endfunction

    function insn_is_F2;
        input [`INSN_OPC_RANGE] insn_ops;
        begin
            insn_is_F2 = (insn_ops == `SET_CONST);
        end
    endfunction

    function insn_is_F3;
        input [`INSN_OPC_RANGE] insn_ops;
        begin
            insn_is_F3 = (insn_ops == `ST);
        end
    endfunction

    function insn_is_F4;
        input [`INSN_OPC_RANGE] insn_ops;
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

    reg [`INSN_PTR_RANGE] insn_ptr_r;
    reg [`INSN_PTR_RANGE] FD_insn_ptr_r; //FIXME: они точно нужны?
    reg [`INSN_PTR_RANGE] DX_insn_ptr_r;

    //случай с st учтен под байпасом
    wire stall = (DX_insn_opc == `READY)
        | (DX_insn_opc == `LD) & (((FD_insn_is_F1 | FD_insn_is_F4) & DX_insn_dst == FD_insn_src_0) |
        FD_insn_is_F1 & DX_insn_dst == FD_insn_src_1);

    wire [`REG_RANGE] W_result;
    wire init_R0 = Start & Ready & init_R0_flag;
    wire [`REG_RANGE] D_src_0_data;
    wire [`REG_RANGE] D_src_1_data;
    wire [`REG_RANGE] D_src_2_data;

    reg [`REG_RANGE] DX_src_0_data_r;
    reg [`REG_RANGE] DX_src_1_data_r;
    reg [`REG_RANGE] DX_src_2_data_r;

    wire reset_RF = reset;

    RegisterFile RegisterFile(.reset_RF(reset_RF), .clk(clk), .init_R0(init_R0), .init_R0_data(init_R0_data),
        .W_result(W_result), .FD_insn_src_0(FD_insn_src_0), .FD_insn_src_1(FD_insn_src_1),
        .FD_insn_src_2(FD_insn_src_2), .MW_insn_dst(MW_insn_dst), .MW_insn_src_0(MW_insn_src_0),
        .MW_insn_is_F1(MW_insn_is_F1), .MW_insn_is_F2(MW_insn_is_F2), .D_src_0_data(D_src_0_data),
        .D_src_1_data(D_src_1_data), .D_src_2_data(D_src_2_data));

    wire init_insn_mem = Start & Ready;
    wire [`INSN_RANGE] curr_insn;

    InsnMemory InsnMemory(.clk(clk), .reset(reset), .init_insn_mem(init_insn_mem), .insn_data(insn_data),
        .insn_ptr(insn_ptr_r), .insn_curr(curr_insn));

    //это байпасы пошли
    wire [`REG_RANGE] X_src_0_data =  //случай с ld вырезан с помошью stall
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_0 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_0) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_0 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_0) ?
        W_result :DX_src_0_data_r;
    wire [`REG_RANGE] X_src_1_data =
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_1 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_1) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_1 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_1) ?
        W_result :DX_src_1_data_r;
    wire [`REG_RANGE] X_src_2_data =
        (XM_insn_is_F1 & XM_insn_dst == DX_insn_src_2 | XM_insn_is_F2 & XM_insn_src_0 == DX_insn_src_2) ?
        M_O_data :
        (MW_insn_is_F1 & MW_insn_dst == DX_insn_src_2 | MW_insn_is_F2 & MW_insn_src_0 == DX_insn_src_2) ?
        W_result :DX_src_2_data_r;

    wire [`REG_RANGE] src_0_data_ALU = X_src_0_data;
    wire [`REG_RANGE] src_1_data_ALU = X_src_1_data;
    wire [`REG_RANGE] X_result_ALU;
    wire X_branch_cond_ALU;

    ALU ALU(.src_0_data_ALU(src_0_data_ALU), .src_1_data_ALU(src_1_data_ALU), .DX_insn_opc(DX_insn_opc),
        .X_result_ALU(X_result_ALU), .X_branch_cond_ALU(X_branch_cond_ALU));

    wire X_branch_cond = X_branch_cond_ALU & DX_insn_is_F4; //под F4 только переходы

    reg [`REG_RANGE] XM_O_data_r;
    reg [`REG_RANGE] XM_B_data_r;
    reg [`REG_RANGE] XM_C_data_r;

    wire [`REG_RANGE] X_O_data = (DX_insn_opc == `ST | DX_insn_opc == `LD) ? X_src_0_data :
        (~DX_insn_is_F2) ? X_result_ALU :
        ((DX_insn_src_0 == 0) ? {{(`REG_SIZE - `CORE_ID_SIZE){1'b0}}, CORE_ID[`CORE_ID_RANGE]}
        : MW_insn_const);
    wire [`REG_RANGE] X_B_data = X_src_1_data;
    wire [`REG_RANGE] X_C_data = X_src_2_data;
    //addr = {XM_src_ld_st_data, XM_src_O_data}

    reg [`REG_RANGE] MW_O_data_r;
    reg [`REG_RANGE] MW_D_data_r;
    wire [`REG_RANGE] M_O_data;
    wire [`REG_RANGE] M_D_data;

    wire [`REG_RANGE] M_B_data;
    wire [`REG_RANGE] M_C_data;

    //bypass:
    // если ld в W а st в M
    assign M_O_data = (MW_insn_opc == `LD & (XM_insn_opc == `ST | XM_insn_opc == `LD) & MW_insn_dst == XM_insn_src_0) ?
        MW_D_data_r : XM_O_data_r;
    assign M_B_data = (MW_insn_opc == `LD & (XM_insn_opc == `ST | XM_insn_opc == `LD) & MW_insn_dst == XM_insn_src_1) ?
        MW_D_data_r : XM_B_data_r;
    assign M_C_data = (MW_insn_opc == `LD & XM_insn_opc == `ST & MW_insn_dst == XM_insn_src_2) ?
        MW_D_data_r : XM_C_data_r;
    assign M_D_data = rd_data_M;

    assign addr_M [`ADDR_RANGE] =
        {M_B_data[`CORE_ID_RANGE], M_O_data [`REG_RANGE]};

    wire M_block = (XM_insn_opc == `LD | XM_insn_opc == `ST) & ~ready_M;

    assign enable_M = {2 {XM_insn_opc == `LD}} & {2'b01}
                    | {2 {XM_insn_opc == `ST}} & {2'b10};

    assign wr_data_M = M_C_data;

    wire block_all_pipe = M_block | Ready;

    assign W_result = (MW_insn_opc == `LD) ? MW_D_data_r : MW_O_data_r;

    always @(posedge clk)
        if(reset)
            Ready <= 0;
        else if(Start & Ready)
            Ready <= 0;
        else
            Ready <= (XM_insn_opc == `READY) ? 1 : Ready;

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
                (FD_insn_ptr_r == `INSN_COUNT - 1) ? `READY : curr_insn;

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