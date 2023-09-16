module EnvMem(
    output wire [`TM_RANGE] env_task_memory
);

    wire [`INSN_RANGE] env_task_mem_array [`TM_DEPTH_RANGE][`INSN_COUNT - 1 : 0];

    genvar k;
    genvar i;
    generate
        for (i = 0; i < `TASK_MEM_DEPTH; i = i + 1) begin : env_mem_loop_1
            for(k = 0; k < `INSN_COUNT; k = k + 1) begin : env_mem_loop_2
                assign env_task_memory
                    [(k + 1) * `INSN_SIZE + i * `TASK_MEM_WIDTH - 1 : k * `INSN_SIZE + i * `TASK_MEM_WIDTH] =
                    env_task_mem_array[i][k];
            end
        end
    endgenerate

endmodule