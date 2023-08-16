`timescale 100ns / 100ns

`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"


module top();
reg		   clk 	 = 1'b0;
reg		   reset = 1'b1;
reg [`TM_RANGE]	   data;
reg [`CORES_RANGE] ready;

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

assign ready = TS.Core_Active_Vect;

initial
begin
data[16383:49] = 0;
data[48:0] = {16'hAAAA, 16'hFFFF, 16'b0000000010100000};

end	


always  #1    clk <= ~clk;
initial #2 reset <= 1'b0;

endmodule