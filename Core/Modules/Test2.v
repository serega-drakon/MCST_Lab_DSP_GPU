`include "IncAllCore.def.v"
`include "Core.v"
module Test2;

    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;
    reg init_R0_flag;
    reg [`REG_RANGE] init_R0_data;
    wire [`INSN_BUS_RANGE] insn_data;
    reg Start;
    wire Ready;

    reg [`REG_RANGE] rd_data_M;
    reg ready_M; // != Ready
    wire [`REG_RANGE] wr_data_M;
    wire [`ADDR_RANGE] addr_M;
    wire [1 : 0] enable_M;

    reg [`INSN_RANGE] insn_data_array [`INSN_COUNT - 1 : 0];
    generate
        for(genvar j = 0; j < `INSN_COUNT; j = j + 1) begin : asddasd
            assign insn_data[(j + 1) * `INSN_SIZE - 1 : j * `INSN_SIZE] = insn_data_array[j];
        end
    endgenerate

    Core Core(clk, reset, init_R0_flag, init_R0_data, insn_data, Start, Ready,
        rd_data_M, ready_M, wr_data_M, addr_M, enable_M);

    integer i;
    integer infile;
    integer c;
    initial begin
        infile = $fopen("code.txt", "r");
        for(i = 0; i < `INSN_COUNT; i = i + 1)
            c = $fscanf(infile, "%x", insn_data_array[i]);
        $display(c);
        for(i = 0; i < `INSN_COUNT; i = i + 1)
            $display("%x", insn_data_array[i], " ");
        $display("\n");
        #300;
        for(i = 0; i < `INSN_COUNT; i = i + 1)
            c = $fscanf(infile, "%x", insn_data_array[i]);
        $display(c);
        for(i = 0; i < `INSN_COUNT; i = i + 1)
            $display("%x", insn_data_array[i], " ");
        $display("\n");
        $fclose(infile);
    end

    initial begin
        reset <= 1;
        Start <= 0;
        init_R0_flag <= 0;
        init_R0_data <= 0;
        ready_M <= 1;
        #10 reset <= 0;
        Start <= 1;
        #10 Start <= 0;
        #400 Start <= 1;
        #10 Start <= 0;

    end

    always @(posedge clk) begin
        if(enable_M == 2'b10)
            $display(wr_data_M);
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