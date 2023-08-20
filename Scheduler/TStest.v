`define Test1
//`define Test2


`timescale 100ns / 100ns

`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"


module top();
reg			clk;
reg			reset;
reg	[`TM_RANGE]	data;
reg	[`CORES_RANGE]	ready;
wire	[`IF_NUM_RANGE] IF_num;	
wire	[`CORES_RANGE]	CAV;
wire	[`IF_NUM_RANGE]	TP;

reg	[1:0] 		task_len;

reg	[14:0]		i;

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


assign IF_num = TS.Insn_Frame_Num;
assign CAV    = TS.Core_Active_Vect;
assign TP     = TS.Task_Pointer;



always  #1    clk <= ~clk;

always @(ready)
	task_len = 2'b00;


initial 
begin
	reset 	 <= 1'b1;
	clk   	 <= 1'b0;
	task_len <= 2'b00;

	#3 reset <= 1'b0;
	   ready <= 16'hFFFF;
end



`ifdef Test1								//ACQ+ACQ
initial begin						
	for (i = 0; i < 16384; i = i + 1)
		data[i] = 1;
      //data[256*i + 47 : 256*i+ 0] = {16'Init_R0_Vect, 16'Core_Active_Vect, 8'reserve, 2'fence, 6'IF_Num};

	data[47 : 0] 		 = {16'h1111, 16'h0F0F, 8'h0, `ACQ, 6'd4};
	data[256*5+47 : 256*5+0] = {16'h2222, 16'hF0F0, 8'h0, `ACQ, 6'd2};
	data[256*8+47 : 256*8+0] = {16'hF0F0, 16'h0F0F, 8'h0, `ACQ, 6'd4};
	data[256*13+47:256*13+0] = {16'h0F0F, 16'hF0F0, 8'h0, `ACQ, 6'd2};
	
end

always @(posedge clk)
begin
	task_len <= task_len + 1;

	if (IF_num != 0 & TP != 6'b111111)				
		ready <= ~CAV;

	if (TP != 6'b111111 & task_len == 2'b10)			//1 IF = 3 tacts
		ready <= ready | CAV;
end

initial
	#250 finish;

`elsif Test2								//NO+ACQ
initial begin						
	for (i = 0; i < 16384; i = i + 1)
		data[i] = 1;
      //data[256*i + 47 : 256*i+ 0] = {16'Init_R0_Vect, 16'Core_Active_Vect, 8'reserve, 2'fence, 6'IF_Num};

	data[47 : 0] 		 = {16'h1111, 16'hF0F0, 8'h0, `NO, 6'd2};
	data[256*3+47 : 256*3+0] = {16'h2222, 16'h0F0F, 8'h0, `ACQ, 6'd2};
	
end

initial									//1 IF = 4 tacts
begin
	#3;								//START
	#4 ready = 16'h0F0F;						//1 IF (NO): start
	#8 ready = 16'hFFFF;						//1 IF (NO): end
	#2 ready = 16'h0F0F;						//2 IF (NO): start
	
	#6 ready = 16'h0000;						//1 IF(ACQ): start
	#2 ready = 16'hF0F0;						//2 IF (NO): end
	#6 ready = 16'hFFFF;						//1 IF(ACQ): end

	#2 ready = 16'hF0F0;						//2 IF(ACQ): start
	#8 ready = 16'hFFFF;						//2 IF(ACQ): end
	#2 $finish();							//FINISH
	
end
`endif //Test2

endmodule
