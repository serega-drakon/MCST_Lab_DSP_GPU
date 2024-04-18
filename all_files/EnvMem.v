`include "IncAllTest.def.v"
module EnvMem(
    output wire [`TM_RANGE] env_task_memory
);

    wire [`INSN_RANGE] env_task_mem_array [`TM_DEPTH_RANGE][`INSN_COUNT - 1 : 0];

    assign env_task_mem_array[0][0] = 16'h0002;
    assign env_task_mem_array[0][1] = 16'hffff;
    assign env_task_mem_array[0][2] = 16'h0000;
    assign env_task_mem_array[0][3] = 16'h0000;
    assign env_task_mem_array[0][4] = 16'h0000;
    assign env_task_mem_array[0][5] = 16'h0000;
    assign env_task_mem_array[0][6] = 16'h0000;
    assign env_task_mem_array[0][7] = 16'h0000;
    assign env_task_mem_array[0][8] = 16'h0000;
    assign env_task_mem_array[0][9] = 16'h0000;
    assign env_task_mem_array[0][10] = 16'h0000;
    assign env_task_mem_array[0][11] = 16'h0000;
    assign env_task_mem_array[0][12] = 16'h0000;
    assign env_task_mem_array[0][13] = 16'h0000;
    assign env_task_mem_array[0][14] = 16'h0000;
    assign env_task_mem_array[0][15] = 16'h0000;
    assign env_task_mem_array[1][0] = 16'hc008;
    assign env_task_mem_array[1][1] = 16'hc041;
    assign env_task_mem_array[1][2] = 16'h3182;
    assign env_task_mem_array[1][3] = 16'h1123;
    assign env_task_mem_array[1][4] = 16'hc014;
    assign env_task_mem_array[1][5] = 16'hc407;
    assign env_task_mem_array[1][6] = 16'hc006;
    assign env_task_mem_array[1][7] = 16'hf000;
    assign env_task_mem_array[1][8] = 16'h0000;
    assign env_task_mem_array[1][9] = 16'h0000;
    assign env_task_mem_array[1][10] = 16'h0000;
    assign env_task_mem_array[1][11] = 16'h0000;
    assign env_task_mem_array[1][12] = 16'h0000;
    assign env_task_mem_array[1][13] = 16'h0000;
    assign env_task_mem_array[1][14] = 16'h0000;
    assign env_task_mem_array[1][15] = 16'h0000;
    assign env_task_mem_array[2][0] = 16'hc005;
    assign env_task_mem_array[2][1] = 16'h1520;
    assign env_task_mem_array[2][2] = 16'hd680;
    assign env_task_mem_array[2][3] = 16'h1646;
    assign env_task_mem_array[2][4] = 16'h1545;
    assign env_task_mem_array[2][5] = 16'h275e;
    assign env_task_mem_array[2][6] = 16'hee10;
    assign env_task_mem_array[2][7] = 16'h1242;
    assign env_task_mem_array[2][8] = 16'h232f;
    assign env_task_mem_array[2][9] = 16'hef00;
    assign env_task_mem_array[2][10] = 16'hf000;
    assign env_task_mem_array[2][11] = 16'h0000;
    assign env_task_mem_array[2][12] = 16'h0000;
    assign env_task_mem_array[2][13] = 16'h0000;
    assign env_task_mem_array[2][14] = 16'h0000;
    assign env_task_mem_array[2][15] = 16'h0000;
    assign env_task_mem_array[3][0] = 16'h4300;
    assign env_task_mem_array[3][1] = 16'h0000;
    assign env_task_mem_array[3][2] = 16'h0000;
    assign env_task_mem_array[3][3] = 16'h0000;
    assign env_task_mem_array[3][4] = 16'h0000;
    assign env_task_mem_array[3][5] = 16'h0000;
    assign env_task_mem_array[3][6] = 16'h0000;
    assign env_task_mem_array[3][7] = 16'h0000;
    assign env_task_mem_array[3][8] = 16'h0000;
    assign env_task_mem_array[3][9] = 16'h0000;
    assign env_task_mem_array[3][10] = 16'h0000;
    assign env_task_mem_array[3][11] = 16'h0000;
    assign env_task_mem_array[3][12] = 16'h0000;
    assign env_task_mem_array[3][13] = 16'h0000;
    assign env_task_mem_array[3][14] = 16'h0000;
    assign env_task_mem_array[3][15] = 16'h0000;

    genvar k;
    genvar i;
    generate
        for (i = 4; i < `TASK_MEM_DEPTH; i = i + 1) begin : env_mem_loop_1
            for(k = 0; k < `INSN_COUNT; k = k + 1) begin : env_mem_loop_2
                assign env_task_mem_array[i][k] = 0;
            end
        end
    endgenerate


    generate
        for (i = 0; i < `TASK_MEM_DEPTH; i = i + 1) begin : env_mem_loop_3
            for(k = 0; k < `INSN_COUNT; k = k + 1) begin : env_mem_loop_4
                assign env_task_memory
                    [(k + 1) * `INSN_SIZE + i * `TASK_MEM_WIDTH - 1 : k * `INSN_SIZE + i * `TASK_MEM_WIDTH] =
                    env_task_mem_array[i][k];
            end
        end
    endgenerate

endmodule