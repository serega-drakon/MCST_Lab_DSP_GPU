`include "IncAllTest.def.v"
`include "Core.v"
`include "sh_mem_uns.v"
`include "TS.v"

module TestCoresMemory;
    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;

    reg [`INSN_RANGE] env_task_mem_array [`TM_DEPTH_RANGE][`INSN_COUNT - 1 : 0];
    wire [`TM_RANGE] env_task_memory;

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
    wire [1 : 0] enable_M [`CORES_RANGE];

    Task_Scheduler TS(clk, reset, env_task_memory, Ready, Start, insn_load_counter,
                      insn_data, init_R0_flag, init_R0_data);

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
    reg dump;

    sh_mem_uns sh_mem_uns
               (clk, reset, enable_arb, addr_arb, wr_data_arb, rd_data_arb, ready_arb, dump);

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_wire_arb
            assign enable_arb[`ENABLE_SIZE * (i + 1) - 1 : `ENABLE_SIZE * i] = enable_M[i];
            assign addr_arb[`ADDR_SIZE * (i + 1) - 1 : `ADDR_SIZE * i] = addr_M[i];
            assign wr_data_arb[`REG_SIZE * (i + 1) - 1 : `REG_SIZE  * i] = wr_data_M[i];
            assign rd_data_M[i] = rd_data_arb[`REG_SIZE * (i + 1) - 1 : `REG_SIZE * i];
            assign ready_M[i] = ready_arb[i];
        end
    endgenerate

    generate
        for(i = 4; i < `TASK_MEM_DEPTH; i = i + 1) begin : initial_loop_1
            for(k = 0; k < `INSN_COUNT; k = k + 1) begin : env_mem_loop_2
                initial
                    env_task_mem_array[i][k] <= 0;
            end
        end
    endgenerate

    integer infile;
    integer c;
    integer l, m;
    integer value;

    initial begin
        #1;
        infile = $fopen("code.txt", "r");
        for(l = 0; l < 5; l = l + 1) begin
            for(m = 0; m < `INSN_COUNT; m = m + 1) begin
                c <= $fscanf(infile, "%x", value);
                env_task_mem_array[l][m] <= value;
                $display("%x ", env_task_mem_array[l][m]);
            end
            $display("\n");
        end
        $fclose(infile);
    end

    initial begin
        reset <= 1;
        #10 reset <= 0;
        #90000 dump <= 1;
        #10 dump <= 0;
    end

    //dump settings
    initial begin
        $monitor();
    end

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0);
    end

    initial begin
        #100000;
        $finish();
    end
endmodule