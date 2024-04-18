`include "IncAllCore.def.v"
`include "RegisterFile.v"
`include "InsnMemory.v"
`include "ALU.v"

module Core #(
    parameter CORE_ID = 0
)(
    input wire clk,
    input wire reset,

    input wire                      init_R0_flag,
    input wire [`REG_RANGE]         init_R0_data,
    input wire [`INSN_BUS_RANGE]    insn_data,
    input wire [`INSN_LOAD_COUNTER_RANGE] insn_load_counter,
    input wire                      Start,
    output wire                     Ready,

    input wire  [`REG_RANGE]        rd_data_M,
    input wire                      ready_M, // != Ready
    output wire [`REG_RANGE]        wr_data_M,
    output wire [`ADDR_RANGE]       addr_M,
    output wire [`ENABLE_RANGE]     enable_M
    );

    reg [`INSN_RANGE]       insn_FD_r;
    reg [`INSN_RANGE]       insn_DX_r;
    reg [`INSN_RANGE]       insn_XM_r;
    reg [`INSN_RANGE]       insn_MW_r;

    wire [`INSN_OPC_RANGE]      insn_curr_opc = insn_curr[`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE]      insn_FD_opc =   insn_FD_r[`INSN_OPC_OFFSET_RANGE];  //for a convenience
    wire [`INSN_OPC_RANGE]      insn_DX_opc =   insn_DX_r[`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE]      insn_XM_opc =   insn_XM_r[`INSN_OPC_OFFSET_RANGE];
    wire [`INSN_OPC_RANGE]      insn_MW_opc =   insn_MW_r[`INSN_OPC_OFFSET_RANGE];

    wire [`INSN_SRC_0_RANGE]    insn_curr_src_0 = insn_curr[`INSN_SRC_0_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE]    insn_FD_src_0 = insn_FD_r[`INSN_SRC_0_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE]    insn_DX_src_0 = insn_DX_r[`INSN_SRC_0_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE]    insn_XM_src_0 = insn_XM_r[`INSN_SRC_0_OFFSET_RANGE];
    wire [`INSN_SRC_0_RANGE]    insn_MW_src_0 = insn_MW_r[`INSN_SRC_0_OFFSET_RANGE];

    wire [`INSN_SRC_1_RANGE]    insn_curr_src_1 = insn_curr[`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE]    insn_FD_src_1 = insn_FD_r[`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE]    insn_DX_src_1 = insn_DX_r[`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE]    insn_XM_src_1 = insn_XM_r[`INSN_SRC_1_OFFSET_RANGE];
    wire [`INSN_SRC_1_RANGE]    insn_MW_src_1 = insn_MW_r[`INSN_SRC_1_OFFSET_RANGE];

    wire [`INSN_SRC_2_RANGE]    insn_curr_src_2 = insn_curr[`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE]    insn_FD_src_2 = insn_FD_r[`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE]    insn_DX_src_2 = insn_DX_r[`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE]    insn_XM_src_2 = insn_XM_r[`INSN_SRC_2_OFFSET_RANGE];
    wire [`INSN_SRC_2_RANGE]    insn_MW_src_2 = insn_MW_r[`INSN_SRC_2_OFFSET_RANGE];

    wire [`INSN_DST_RANGE]      insn_curr_dst = insn_curr[`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE]      insn_FD_dst = insn_FD_r[`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE]      insn_DX_dst = insn_DX_r[`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE]      insn_XM_dst = insn_XM_r[`INSN_DST_OFFSET_RANGE];
    wire [`INSN_DST_RANGE]      insn_MW_dst = insn_MW_r[`INSN_DST_OFFSET_RANGE];

    wire [`INSN_CONST_RANGE]    insn_curr_const = insn_curr[`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE]    insn_FD_const = insn_FD_r[`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE]    insn_DX_const = insn_DX_r[`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE]    insn_XM_const = insn_XM_r[`INSN_CONST_OFFSET_RANGE];
    wire [`INSN_CONST_RANGE]    insn_MW_const = insn_MW_r[`INSN_CONST_OFFSET_RANGE];

    wire [`INSN_TARGET_RANGE]   insn_curr_target = insn_curr[`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE]   insn_FD_target = insn_FD_r[`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE]   insn_DX_target = insn_DX_r[`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE]   insn_XM_target = insn_XM_r[`INSN_TARGET_OFFSET_RANGE];
    wire [`INSN_TARGET_RANGE]   insn_MW_target = insn_MW_r[`INSN_TARGET_OFFSET_RANGE];

    function insn_is_F0; // insn-s without arguments
        input [`INSN_OPC_RANGE] insn_opc;
        begin
            insn_is_F0 = (insn_opc == `NOP | insn_opc == `READY);
        end
    endfunction

    function insn_is_F1;
        input [`INSN_OPC_RANGE] insn_opc;
        begin
            insn_is_F1 = (insn_opc == `ADD | insn_opc == `SUB | insn_opc == `MUL
                | insn_opc == `DIV | insn_opc == `CMPGE | insn_opc == `RSHIFT
                | insn_opc == `LSHIFT | insn_opc == `AND | insn_opc == `OR
                | insn_opc == `XOR | insn_opc == `LD);
        end
    endfunction

    function insn_is_F2;
        input [`INSN_OPC_RANGE] insn_opc;
        begin
            insn_is_F2 = (insn_opc == `SET_CONST);
        end
    endfunction

    function insn_is_F3;
        input [`INSN_OPC_RANGE] insn_opc;
        begin
            insn_is_F3 = (insn_opc == `ST);
        end
    endfunction

    function insn_is_F4;
        input [`INSN_OPC_RANGE] insn_opc;
        begin
            insn_is_F4 = (insn_opc == `BNZ);
        end
    endfunction

    function insn_set_const_mode;
        input [`INSN_DST_RANGE] insn_dst;
        begin
            insn_set_const_mode = (insn_dst < `SET_CONST_MODE_REG);
        end
    endfunction

    wire insn_FD_is_F0 = insn_is_F0(insn_FD_opc);
    wire insn_DX_is_F0 = insn_is_F0(insn_DX_opc);
    wire insn_XM_is_F0 = insn_is_F0(insn_XM_opc);
    wire insn_MW_is_F0 = insn_is_F0(insn_MW_opc);

    wire insn_FD_is_F1 = insn_is_F1(insn_FD_opc);
    wire insn_DX_is_F1 = insn_is_F1(insn_DX_opc);
    wire insn_XM_is_F1 = insn_is_F1(insn_XM_opc);
    wire insn_MW_is_F1 = insn_is_F1(insn_MW_opc);

    wire insn_FD_is_F2 = insn_is_F2(insn_FD_opc);
    wire insn_DX_is_F2 = insn_is_F2(insn_DX_opc);
    wire insn_XM_is_F2 = insn_is_F2(insn_XM_opc);
    wire insn_MW_is_F2 = insn_is_F2(insn_MW_opc);

    wire insn_FD_is_F3 = insn_is_F3(insn_FD_opc);
    wire insn_DX_is_F3 = insn_is_F3(insn_DX_opc);
    wire insn_XM_is_F3 = insn_is_F3(insn_XM_opc);
    wire insn_MW_is_F3 = insn_is_F3(insn_MW_opc);

    wire insn_FD_is_F4 = insn_is_F4(insn_FD_opc);
    wire insn_DX_is_F4 = insn_is_F4(insn_DX_opc);
    wire insn_XM_is_F4 = insn_is_F4(insn_XM_opc);
    wire insn_MW_is_F4 = insn_is_F4(insn_MW_opc);

    wire insn_FD_set_const_mode = insn_set_const_mode(insn_FD_dst);
    wire insn_DX_set_const_mode = insn_set_const_mode(insn_DX_dst);
    wire insn_XM_set_const_mode = insn_set_const_mode(insn_XM_dst);
    wire insn_MW_set_const_mode = insn_set_const_mode(insn_MW_dst);

    reg [`INSN_PTR_RANGE] insn_ptr_r;
    reg insn_FD_is_last_r;

    reg Ready_r;
    assign Ready = Ready_r;

    wire [`REG_RANGE] W_result;
    wire init_R0 = Start & Ready_r & init_R0_flag;
    wire [`REG_RANGE] D_src_0_data_RF;
    wire [`REG_RANGE] D_src_1_data_RF;
    wire [`REG_RANGE] D_src_2_data_RF;

    reg [`REG_RANGE] DX_src_0_data_r;
    reg [`REG_RANGE] DX_src_1_data_r;
    reg [`REG_RANGE] DX_src_2_data_r;

    wire reset_RF = reset;

    RegisterFile RegisterFile(.reset_RF(reset_RF), .clk(clk), .init_R0(init_R0),
        .init_R0_data(init_R0_data), .W_result(W_result), .FD_insn_src_0(insn_FD_src_0),
        .FD_insn_src_1(insn_FD_src_1), .FD_insn_src_2(insn_FD_src_2), .MW_insn_dst(insn_MW_dst),
        .MW_insn_is_F1(insn_MW_is_F1), .MW_insn_is_F2(insn_MW_is_F2), .D_src_0_data_RF(D_src_0_data_RF),
        .D_src_1_data_RF(D_src_1_data_RF), .D_src_2_data_RF(D_src_2_data_RF));

    // Register File bypasses
    wire [`REG_RANGE] D_src_0_data =
        ((insn_DX_is_F1 | insn_DX_is_F2) & insn_DX_dst == insn_FD_src_0) ?
            X_O_data :
        ((insn_XM_is_F1 | insn_XM_is_F2) & insn_XM_dst == insn_FD_src_0) ?
            M_O_data :
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_FD_src_0) ?
            W_result : D_src_0_data_RF;
    wire [`REG_RANGE] D_src_1_data =
        ((insn_DX_is_F1 | insn_DX_is_F2) & insn_DX_dst == insn_FD_src_1) ?
            X_O_data :
        ((insn_XM_is_F1 | insn_XM_is_F2) & insn_XM_dst == insn_FD_src_1) ?
            M_O_data :
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_FD_src_1) ?
            W_result : D_src_1_data_RF;
    wire [`REG_RANGE] D_src_2_data =
        ((insn_DX_is_F1 | insn_DX_is_F2) & insn_DX_dst == insn_FD_src_2) ?
            X_O_data :
        ((insn_XM_is_F1 | insn_XM_is_F2) & insn_XM_dst == insn_FD_src_2) ?
            M_O_data :
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_FD_src_2) ?
            W_result : D_src_2_data_RF;

    wire D_fast_branch_cond = D_src_0_data != 0 & insn_FD_is_F4;

    wire init_insn_mem = Start & Ready_r;
    wire [`INSN_RANGE] insn_curr;

    InsnMemory InsnMemory(.clk(clk), .reset(reset), .init_insn_mem(init_insn_mem),
        .insn_data(insn_data), .insn_ptr(insn_ptr_r), .insn_load_counter(insn_load_counter),
        .insn_curr(insn_curr));

    // bypasses
    wire [`REG_RANGE] X_src_0_data =  // ld case taken by stall
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_DX_src_0) ?
        W_result : DX_src_0_data_r;
    wire [`REG_RANGE] X_src_1_data =
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_DX_src_1) ?
        W_result : DX_src_1_data_r;
    wire [`REG_RANGE] X_src_2_data =
        ((insn_MW_is_F1 | insn_MW_is_F2) & insn_MW_dst == insn_DX_src_2) ?
        W_result : DX_src_2_data_r;

    wire [`REG_RANGE] src_0_data_ALU = X_src_0_data;
    wire [`REG_RANGE] src_1_data_ALU = X_src_1_data;
    wire [`REG_RANGE] X_result_ALU;

    ALU ALU(.src_0_data_ALU(src_0_data_ALU), .src_1_data_ALU(src_1_data_ALU),
        .insn_F2_const_ALU(insn_DX_const), .core_id(CORE_ID[`CORE_ID_RANGE]),
        .insn_set_const_mode(insn_DX_set_const_mode), .DX_insn_opc(insn_DX_opc),
        .X_result_ALU(X_result_ALU));

    reg [`REG_RANGE] XM_O_data_r;
    reg [`REG_RANGE] XM_B_data_r;
    reg [`REG_RANGE] XM_C_data_r;

    wire [`REG_RANGE] X_O_data = X_result_ALU;
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
    // if ld is at W and st/ld is at M
    assign M_O_data = (insn_MW_opc == `LD & (insn_XM_opc == `ST | insn_XM_opc == `LD) & insn_MW_dst == insn_XM_src_0) ?
        MW_D_data_r : XM_O_data_r;
    assign M_B_data = (insn_MW_opc == `LD & (insn_XM_opc == `ST | insn_XM_opc == `LD) & insn_MW_dst == insn_XM_src_1) ?
        MW_D_data_r : XM_B_data_r;
    assign M_C_data = (insn_MW_opc == `LD & insn_XM_opc == `ST & insn_MW_dst == insn_XM_src_2) ?
        MW_D_data_r : XM_C_data_r;
    assign M_D_data = rd_data_M;

    assign addr_M [`ADDR_RANGE] =
        {M_B_data[`CORE_ID_RANGE], M_O_data [`REG_RANGE]};

    assign enable_M = {`ENABLE_SIZE {insn_XM_opc == `LD}} & {`ENABLE_READ}
                    | {`ENABLE_SIZE {insn_XM_opc == `ST}} & {`ENABLE_WRITE};

    assign wr_data_M = M_C_data;

    assign W_result = (insn_MW_opc == `LD) ? MW_D_data_r : MW_O_data_r;

    wire M_block = (insn_XM_opc == `LD | insn_XM_opc == `ST) & ~ready_M;
    wire block_all_pipe = M_block | Ready_r;

    wire stall_Ready = insn_DX_opc == `READY;
    wire stall_data = (insn_DX_opc == `LD) & (((insn_FD_is_F1 | insn_FD_is_F4) & insn_DX_dst == insn_FD_src_0) |
        insn_FD_is_F1 & insn_DX_dst == insn_FD_src_1);
    wire stall_D_branch = insn_FD_is_F4 & insn_MW_opc == `LD;
    // st/ld case taken by bypass
    wire stall = stall_Ready | stall_data | stall_D_branch;

    always @(posedge clk)
            Ready_r <= (reset) ? 1 :
                (Start & Ready_r & insn_load_counter == `INSN_LOAD_TIME - 1) ? 0 :
                (insn_XM_opc == `READY) ? 1 : Ready_r;

    always @(posedge clk)
        insn_ptr_r <= (reset | Start & Ready) ? 0 :
            (stall | block_all_pipe) ? insn_ptr_r :
            (D_fast_branch_cond) ? insn_FD_target : insn_ptr_r + 1;

    always @(posedge clk)
        insn_FD_is_last_r <= (reset | Start & Ready | D_fast_branch_cond) ? 0 :
            (insn_ptr_r == `INSN_COUNT - 1 & ~stall & ~block_all_pipe) ? 1 : insn_FD_is_last_r;

    wire [`INSN_RANGE] insn_Ready = {`READY, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};

    always @(posedge clk)
        insn_FD_r <= (reset | Start & Ready) ? `NOP :
            (stall | block_all_pipe) ? insn_FD_r :
            (D_fast_branch_cond) ? `NOP :
            (insn_FD_is_last_r) ? insn_Ready : insn_curr;

    always @(posedge clk)
        insn_DX_r <= (reset | Start & Ready) ? `NOP :
            (block_all_pipe) ? insn_DX_r:
            (stall) ? `NOP : insn_FD_r;

    always @(posedge clk)
        insn_XM_r <= (reset) ? `NOP :
            (block_all_pipe) ? insn_XM_r : insn_DX_r;

    always @(posedge clk)
        insn_MW_r <= (reset) ? `NOP :
            (block_all_pipe) ? insn_MW_r : insn_XM_r;

    always @(posedge clk)
        DX_src_0_data_r <= (block_all_pipe) ? DX_src_0_data_r :D_src_0_data;

    always @(posedge clk)
        DX_src_1_data_r <= (block_all_pipe) ? DX_src_1_data_r :D_src_1_data;

    always @(posedge clk)
        DX_src_2_data_r <= (block_all_pipe) ? DX_src_2_data_r :D_src_2_data;

    always @(posedge clk)
        XM_O_data_r <= (block_all_pipe) ? XM_O_data_r : X_O_data;

    always @(posedge clk)
        XM_B_data_r <= (block_all_pipe) ? XM_B_data_r : X_B_data;

    always @(posedge clk)
        XM_C_data_r <= (block_all_pipe) ? XM_C_data_r : X_C_data;

    always @(posedge clk)
        MW_O_data_r <= (block_all_pipe) ? MW_O_data_r : M_O_data;

    always @(posedge clk)
        MW_D_data_r <= (insn_XM_opc == `LD & ~block_all_pipe) ? M_D_data : MW_D_data_r;

endmodule