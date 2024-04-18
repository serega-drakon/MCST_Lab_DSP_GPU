`include "GPU.v"
module test4090TI;
    reg clk = 1;
    always #5 clk = ~clk;
    reg reset;
    initial begin
        reset <= 1;
        #10 reset <= 0;
    end

    GPU GPU(
        .clk(clk),
        .reset(reset),
        .vga_clk(),
        .red_vga(),
        .green_vga(),
        .blue_vga(),
        .h_sync(),
        .v_sync(),
        .blank_n(),
        .sync_n()
    );

    initial begin
        $dumpfile("test.vcd");
        $dumpvars(0);
    end

    initial begin
        #250000;
        $finish();
    end
endmodule