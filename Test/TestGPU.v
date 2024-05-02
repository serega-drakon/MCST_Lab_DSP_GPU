`include "Core.v"
`include "TS.v"
`include "sh_mem.v"
`include "EnvMem.v"
`include "sram_conn_debug.v"
//`include "IncAllTest.def.v"
`include "vga_machine.v"

module TestCoresMemory;
    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;

    //VGA
    wire                vga_clk;
    wire [`REG_RANGE]   red_vga;
    wire [`REG_RANGE]   green_vga;
    wire [`REG_RANGE]   blue_vga ;
    wire                h_sync;
    wire                v_sync;
    wire                blank_n;
    wire                sync_n;
    //SRAM
    wire [19:0] sram_addr;
    wire [15:0] sram_dq;
    wire        sram_ce_n;
    wire        sram_oe_n;
    wire        sram_we_n;
    wire        sram_ub_n;
    wire        sram_lb_n;

    wire [`TM_RANGE]            env_task_memory;
    EnvMem EM(
        .env_task_memory    (env_task_memory)
    );

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

    wire vga_en;
    wire vga_end;
    wire [`REG_RANGE] vga_data;
    wire [`ADDR_RANGE] vga_addr;

    Task_Scheduler TS(
        .clk                (clk),
        .reset              (reset),
        .env_task_memory    (env_task_memory),
        .Ready              (Ready),
        .Start              (Start),
        .Insn_Load_Counter  (insn_load_counter),
        .Insn_Data          (insn_data),
        .Init_R0_Vect       (init_R0_flag),
        .Init_R0            (init_R0_data),
        .vga_en             (vga_en),
        .vga_end            (vga_end)
    );

    genvar i;
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

    wire vga_copy_en;
    wire [`ADDR_RANGE]	vga_copy_addr;
    wire [`REG_RANGE]	vga_data_out;

    wire vga_copy_moment = ~(h_sync & v_sync);


    sh_mem
        sh_mem (
            .clk                (clk),
            .reset              (reset),
            .enable             (enable_arb),
            .addr               (addr_arb),
            .wr_data            (wr_data_arb),
            .rd_data            (rd_data_arb),
            .ready              (ready_arb),

            .vga_en		        (vga_en),
            .vga_data	        (vga_data),
            .vga_addr_copy      (vga_copy_addr),
            .vga_copy	        (vga_copy_en),
            .vga_end		    (vga_end),
            .vga_copy_moment    (vga_copy_moment)
        );

    reg                 dump;
    wire                sram_write
                        = vga_copy_en && ~(h_sync & v_sync);
    wire                sram_read
                        = ~sram_write;
    wire [`ADDR_RANGE]  sram_vga_addr
                        = sram_write ? vga_copy_addr : next_vga_addr;
    wire [`ADDR_RANGE]  next_vga_addr
                        = vga_addr; //fixme

    sram_conn_debug
        sram_conn(
            .clk        (clk),
            .rst        (reset),
            .dump       (dump),

            .write      (sram_write),
            .read       (sram_read),
            .byte_en    (2'b01),
            .addr       (sram_vga_addr),
            .data_in    (vga_data),
            .data_out   (vga_data_out),

            .sram_data  (sram_dq),
            .sram_addr  (sram_addr),
            .sram_ce_n  (sram_ce_n),
            .sram_oe_n  (sram_oe_n),
            .sram_we_n  (sram_we_n),
            .sram_ub_n  (sram_ub_n),
            .sram_lb_n  (sram_lb_n)
        );

    vga_machine
        vga_machine (
            .clk        (clk),
            .rst        (reset),
            .vga_clk    (vga_clk),
            .h_sync     (h_sync),
            .v_sync     (v_sync),
            .blank_n    (blank_n),
            .sync_n     (sync_n),
            .red_vga    (red_vga),
            .green_vga  (green_vga),
            .blue_vga   (blue_vga),
            .vga_addr   (vga_addr),
            .vga_data   (vga_data_out)
        );

    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_wire_arb
            assign enable_arb
                [`ENABLE_SIZE * (i + 1) - 1 : `ENABLE_SIZE * i]
                = enable_M[i];
            assign addr_arb
                [`ADDR_SIZE * (i + 1) - 1 : `ADDR_SIZE * i]
                = addr_M[i];
            assign wr_data_arb
                [`REG_SIZE * (i + 1) - 1 : `REG_SIZE  * i]
                = wr_data_M[i];
            assign rd_data_M[i]
                = rd_data_arb
                    [`REG_SIZE * (i + 1) - 1 : `REG_SIZE * i];
            assign ready_M[i]
                = ready_arb[i];
        end
    endgenerate

    initial begin
        dump <= 0;
        reset <= 1;
        #10 reset <= 0;
        //#200000 dump <= 1;
        //#10 dump <= 0;
    end

    always @(negedge vga_copy_en & ~reset) begin
        #10 dump <= 1;
        #10 dump <= 0;
        //$finish();
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
        #200000;
        $finish();
    end
endmodule