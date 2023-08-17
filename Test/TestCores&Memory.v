`include "IncAllTest.def.v"
`include "Core.v"
`include "arbitrator.v"

module TestCoresMemory;
    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;
    reg init_R0_flag[`CORES_RANGE];
    reg [`REG_RANGE] init_R0_data [`CORES_RANGE];
    reg [`INSN_BUS_RANGE] insn_data ;
    reg Start[`CORES_RANGE];
    wire Ready [`CORES_RANGE];

    wire [`REG_RANGE] rd_data_M [`CORES_RANGE ];
    wire ready_M [`CORES_RANGE]; // != Ready
    wire [`REG_RANGE] wr_data_M [`CORES_RANGE];
    wire [`ADDR_RANGE] addr_M [`CORES_RANGE];
    wire [1 : 0] enable_M [`CORES_RANGE];

    genvar i;
    generate
        for (i = 0; i < `NUM_OF_CORES; i = i + 1) begin : array_cores
            Core #(i) Core_i
            (clk, reset, init_R0_flag[i], init_R0_data[i], insn_data, Start[i], Ready[i],
                rd_data_M[i], ready_M[i], wr_data_M[i], addr_M[i], enable_M[i]);
        end
    endgenerate

    wire [`ENABLE_BUS_RANGE] enable_arb;
    wire [`ADDR_BUS_RANGE] addr_arb;
    wire [`REG_BUS_RANGE] wr_data_arb;
    wire [`REG_BUS_RANGE] rd_data_arb;
    wire [`CORES_RANGE]	ready_arb;

    arbitrator arb(clk, reset, enable_arb, addr_arb, wr_data_arb, rd_data_arb, ready_arb);

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
        for(i = 0; i < `NUM_OF_CORES; i = i + 1) begin : zero_loop
            initial begin
                Start[i] <= 0;
                init_R0_flag[i] <= 0;
                init_R0_data[i] <= 0;
            end
        end
    endgenerate


    initial begin
        reset <= 1;
        insn_data <= 0;
        #10 reset <= 0;
        init_R0_flag[0] <= 1;
        init_R0_data[0] <= 3;
        insn_data[1 * `INSN_SIZE - 1 : 0 * `INSN_SIZE] <= {{`SET_CONST }, {{8'h0}, {4'h1}}};
        insn_data[2 * `INSN_SIZE - 1 : 1 * `INSN_SIZE] <= {{`SET_CONST }, {{8'h0}, {4'h8}}};
        insn_data[3 * `INSN_SIZE - 1 : 2 * `INSN_SIZE] <= {{`ST }, {{4'h1}, {4'h8}, {4'h0}}};
        insn_data[4 * `INSN_SIZE - 1 : 3 * `INSN_SIZE] <= {{`LD }, {{4'h1}, {4'h8}, {4'h0}}};
        insn_data[5 * `INSN_SIZE - 1 : 4 * `INSN_SIZE] <= {{`READY }, {(`INSN_SIZE - `INSN_OPC_SIZE){1'b0}}};
        Start[0] <= 1;
        #10 Start[0] <= 0;
        init_R0_flag[0] <= 0;
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