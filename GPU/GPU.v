`include "Core.v"
`include "TS.v"
`include "sh_mem.v"
`include "EnvMem.v"
`include "IncAllTest.def.v"
`include "vga_machine.v"

module GPU( //todo
    input wire clk,
    input wire reset,

    output wire vga_clk,
    output wire red_vga [`REG_RANGE],
    output wire green_vga [`REG_RANGE],
    output wire blue_vga [`REG_RANGE],
    output wire h_sync,
    output wire v_sync,
    output wire blank_n,
    output wire sync_n
);

    wire [`TM_RANGE]                env_task_memory;
    wire [`CORES_RANGE]             init_R0_flag;
    wire [`REG_BUS_RANGE]           init_R0_data;
    wire [`INSN_BUS_RANGE]          insn_data;
    wire [`CORES_RANGE]             Start;
    wire [`CORES_RANGE]             Ready;
    wire [`INSN_LOAD_COUNTER_RANGE] insn_load_counter;

    wire [`REG_RANGE]       rd_data_M   [`CORES_RANGE];
    wire                    ready_M     [`CORES_RANGE]; // != Ready
    wire [`REG_RANGE]       wr_data_M   [`CORES_RANGE];
    wire [`ADDR_RANGE]      addr_M      [`CORES_RANGE];
    wire [`ENABLE_RANGE]    enable_M    [`CORES_RANGE];

    wire vga;
    wire vga_en;
    wire vga_data;
    wire vga_addr;

    Task_Scheduler TS(
        .clk(clk),
        .reset(reset),
        .env_task_memory    (env_task_memory),
        .Ready              (Ready),
        .Start              (Start),
        .Insn_Load_Counter  (insn_load_counter),
        .Insn_Data          (insn_data),
        .Init_R0_Vect       (init_R0_flag),
        .Init_R0            (init_R0_data),
        .vga                (vga),
        .vga_en             (vga_en)
    );

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_cores
            Core #(
                i
            ) Core_i (
                .clk                (clk),
                .reset              (reset),
                .init_R0_flag       (init_R0_flag[i]),
                .init_R0_data       (init_R0_data[(i + 1) * `REG_SIZE - 1 : i * `REG_SIZE]),
                .insn_data          (insn_data),
                .insn_load_counter  (insn_load_counter),
                .Start              (Start[i]),
                .Ready              (Ready[i]),
                .rd_data_M          (rd_data_M[i]),
                .ready_M            (ready_M[i]),
                .wr_data_M          (wr_data_M[i]),
                .addr_M             (addr_M[i]),
                .enable_M           (enable_M[i])
            );
        end
    endgenerate

    wire [`ENABLE_BUS_RANGE]    enable_arb;
    wire [`ADDR_BUS_RANGE]      addr_arb;
    wire [`REG_BUS_RANGE]       wr_data_arb;
    wire [`REG_BUS_RANGE]       rd_data_arb;
    wire [`CORES_RANGE]	        ready_arb;

    sh_mem
        sh_mem (
            .clk        (clk),
            .reset      (reset),
            .enable     (enable_arb),
            .addr       (addr_arb),
            .wr_data    (wr_data_arb),
            .rd_data    (rd_data_arb),
            .ready      (ready_arb),
            
            .vga_en(vga),
            .vga_addr(vga_addr),
            .vga_data(vga_data),
            .vga_end(vga_en)
        );
        
    vga_machine
	vga_machine (
		.clk(clk),
		.rst(reset),
		.vga_clk(vga_clk),
		.h_sync(h_sync),
		.v_sync(v_sync),
		.blank_n(blank_n),
		.sync_n(sync_n),
		.red_vga(red_vga),
		.green_vga(green_vga),
		.blue_vga(blue_vga),
		.vga_addr(vga_addr),
		.vga_data(vga_data)
	);

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_wire_arb
            assign enable_arb   [`ENABLE_SIZE * (i + 1) - 1 : `ENABLE_SIZE * i] =
                enable_M[i];
            assign addr_arb     [`ADDR_SIZE * (i + 1) - 1 : `ADDR_SIZE * i] =
                addr_M[i];
            assign wr_data_arb  [`REG_SIZE * (i + 1) - 1 : `REG_SIZE  * i] =
                wr_data_M[i];
            assign rd_data_M[i] =
                rd_data_arb     [`REG_SIZE * (i + 1) - 1 : `REG_SIZE * i];
            assign ready_M[i] =
                ready_arb[i];
        end
    endgenerate



endmodule