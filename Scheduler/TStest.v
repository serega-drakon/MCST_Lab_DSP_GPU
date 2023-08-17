`timescale 100ns / 100ns

`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"


module top();
reg			clk   = 1'b0;
reg			reset = 1'b1;
reg	[`TM_RANGE]	data;
reg	[`CORES_RANGE]	ready;

wire	[`IF_NUM_RANGE] tpointer;	

Task_Scheduler TS (
	.clk			( clk	),
	.reset			( reset	),

	.env_task_memory	( data  ),
	.Ready			( ready	),

	.Start			(	),
	.Insn_Data		(	),
	.Init_R0_Vect		(	),
	.Init_R0		(	)
);

assign tpointer = TS.Task_Pointer;
assign ready	= 16'hFFFF;


always  #1    clk <= ~clk;

initial #2 reset <= 1'b0;


genvar i;
generate
	for (i = 0; i <  64; i = i + 1) begin: env_data
		initial data[256*i + 255: 256*i +49] = 2**(255-49) - 1;
		initial data[256*i + 48:  256*i + 0] = {16'hAAAA, 16'hABCD, 8'b00000000, 2'b00, 6'b100000};
	end
endgenerate

initial begin
#500 $finish();
end	

endmodule