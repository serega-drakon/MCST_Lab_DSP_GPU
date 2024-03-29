`include "Core.v"
`include "TS.v"
`include "sh_mem.v"
`include "EnvMem.v"
`include "IncAllTest.def.v"

module GPU( //todo
    input wire clk,
    input wire reset,

    output wire red_vga [`REG_RANGE],
    output wire green_vga [`REG_RANGE],
    output wire blue_vga [`REG_RANGE],
    output wire h_sync,
    output wire v_sync
);

    wire [`TM_RANGE] env_task_memory;
    wire [`CORES_RANGE] init_R0_flag;
    wire [`REG_BUS_RANGE] init_R0_data;
    wire [`INSN_BUS_RANGE] insn_data ;
    wire [`CORES_RANGE] Start;
    wire [`CORES_RANGE] Ready;
    wire [`INSN_LOAD_COUNTER_RANGE] insn_load_counter;

    wire [`REG_RANGE] rd_data_M [`CORES_RANGE ];
    wire ready_M [`CORES_RANGE]; // != Ready
    wire [`REG_RANGE] wr_data_M [`CORES_RANGE];
    wire [`ADDR_RANGE] addr_M [`CORES_RANGE];
    wire [`ENABLE_RANGE] enable_M [`CORES_RANGE];

    wire vga;
    wire vga_en;

    Task_Scheduler TS(clk, reset, env_task_memory, Ready, Start, insn_load_counter,
        insn_data, init_R0_flag, init_R0_data, vga, vga_en);

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_cores
            Core #(i) Core_i
                      (clk, reset, init_R0_flag[i], init_R0_data[(i + 1) * `REG_SIZE - 1 : i * `REG_SIZE],
                          insn_data, insn_load_counter, Start[i], Ready[i], rd_data_M[i], ready_M[i],
                          wr_data_M[i], addr_M[i], enable_M[i]);
        end
    endgenerate

    wire [`ENABLE_BUS_RANGE] enable_arb;
    wire [`ADDR_BUS_RANGE] addr_arb;
    wire [`REG_BUS_RANGE] wr_data_arb;
    wire [`REG_BUS_RANGE] rd_data_arb;
    wire [`CORES_RANGE]	ready_arb;

    sh_mem sh_mem
               (clk, reset, enable_arb, addr_arb, wr_data_arb, rd_data_arb, ready_arb);

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_wire_arb
            assign enable_arb[`ENABLE_SIZE * (i + 1) - 1 : `ENABLE_SIZE * i] = enable_M[i];
            assign addr_arb[`ADDR_SIZE * (i + 1) - 1 : `ADDR_SIZE * i] = addr_M[i];
            assign wr_data_arb[`REG_SIZE * (i + 1) - 1 : `REG_SIZE  * i] = wr_data_M[i];
            assign rd_data_M[i] = rd_data_arb[`REG_SIZE * (i + 1) - 1 : `REG_SIZE * i];
            assign ready_M[i] = ready_arb[i];
        end
    endgenerate

endmodule