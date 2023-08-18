`include "IncAllTest.def.v"
`include "Core.v"
`include "sh_mem_uns.v"

module TestCoresMemory;
    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;
    reg init_R0_flag[`CORES_RANGE];
    reg [`REG_RANGE] init_R0_data [`CORES_RANGE];
    wire [`INSN_BUS_RANGE] insn_data ;
    reg Start[`CORES_RANGE];
    wire Ready [`CORES_RANGE];

    wire [`REG_RANGE] rd_data_M [`CORES_RANGE ];
    wire ready_M [`CORES_RANGE]; // != Ready
    wire [`REG_RANGE] wr_data_M [`CORES_RANGE];
    wire [`ADDR_RANGE] addr_M [`CORES_RANGE];
    wire [1 : 0] enable_M [`CORES_RANGE];

    reg [`INSN_RANGE] insn_data_array [`INSN_COUNT - 1 : 0];
    generate
        for(genvar j = 0; j < `INSN_COUNT; j = j + 1) begin : asddasd
            assign insn_data[(j + 1) * `INSN_SIZE - 1 : j * `INSN_SIZE] = insn_data_array[j];
        end
    endgenerate

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
        for(i = 0; i < `NUM_OF_CORES; i = i + 1) begin : zero_loop
            initial begin
                Start[i] <= 0;
                init_R0_flag[i] <= 0;
                init_R0_data[i] <= 0;
            end
        end
    endgenerate

    integer j;
    integer infile;
    integer c;
    initial begin
        infile = $fopen("code.txt", "r");
        for(j = 0; j < `INSN_COUNT; j = j+ 1)
            c = $fscanf(infile, "%x", insn_data_array[j]);
        $display(c);
        for(j = 0; j < `INSN_COUNT; j = j+ 1)
            $display("%x", insn_data_array[j], " ");
        $display("\n");
        #300;
        for(j = 0; j < `INSN_COUNT; j = j+ 1)
            c = $fscanf(infile, "%x", insn_data_array[j]);
        $display(c);
        for(j = 0; j < `INSN_COUNT; j = j+ 1)
            $display("%x", insn_data_array[j], " ");
        $display("\n");
        $fclose(infile);
    end

    integer k;
    initial begin
        reset <= 1;
        #10 reset <= 0;
        for(k = 0; k < `NUM_OF_CORES; k = k + 1)
            Start[k] <= 1;
        #10;
        for(k = 0; k < `NUM_OF_CORES; k = k + 1)
            Start[k] <= 0;
        #400;
        for(k = 0; k < `NUM_OF_CORES; k = k + 1)
            Start[k] <= 1;
        #10;
        for(k = 0; k < `NUM_OF_CORES; k = k + 1)
            Start[k] <= 0;
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
        #100000 $finish();
    end
endmodule