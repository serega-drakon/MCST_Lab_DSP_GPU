`include "IncAllCore.def.v"
`include "Core.v"
module Test3;

    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;
    reg init_R0_flag;
    reg [`REG_RANGE] init_R0_data;
    reg [`INSN_BUS_RANGE] insn_data;
    reg Start;
    wire Ready;

    reg [`REG_RANGE] rd_data_M;
    reg ready_M; // != Ready
    wire [`REG_RANGE] wr_data_M;
    wire [`ADDR_RANGE] addr_M;
    wire [1 : 0] enable_M;

    reg [`INSN_LOAD_COUNTER_RANGE] insn_load_counter;

    Core Core(clk, reset, init_R0_flag, init_R0_data, insn_data, insn_load_counter,
        Start, Ready, rd_data_M, ready_M, wr_data_M, addr_M, enable_M);

    initial begin
        reset <= 1;
        Start <= 0;
        init_R0_flag <= 0;
        init_R0_data <= 0;
        insn_data <= 0;
        ready_M <= 0;
        #10 reset <= 0;
        insn_data[1 * `INSN_SIZE - 1 : 0 * `INSN_SIZE] <= {{`CMPGE }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
        insn_data[2 * `INSN_SIZE - 1 : 1 * `INSN_SIZE] <= {{`ADD }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
        insn_data[3 * `INSN_SIZE - 1 : 2 * `INSN_SIZE] <= {{`ADD }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
        Start <= 1;
        insn_load_counter <= 0;
        #10 insn_data <= 0;
        insn_load_counter <= 1;
        #10 insn_load_counter <= 2;
        insn_data <= 0;
        #10 insn_load_counter <= 3;
        insn_data[3 * `INSN_SIZE - 1 : 2 * `INSN_SIZE] <= {{`SET_CONST }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
        insn_data[4 * `INSN_SIZE - 1 : 3 * `INSN_SIZE] <= {{`NOP }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
    end

    always @(posedge (enable_M[1])  or posedge(enable_M[0])) begin
        ready_M <= 0;
        #10 ready_M <= 1;
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
        #800 $finish();
    end

endmodule