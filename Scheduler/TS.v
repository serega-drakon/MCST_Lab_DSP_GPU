`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"

module Task_Scheduler
(
	input		wire				clk,				//TS <- Env
	input		wire				reset,				//TS <- Env
	input		wire	[`TM_RANGE]		env_task_memory,		//TS <- Env 


	input		wire	[`CORES_RANGE]		Ready,				//TS <- Cores

	output		reg	[`CORES_RANGE]		Start,				//TS -> Cores
	output		reg	[`INSN_BUS_RANGE]	Insn_Data,			//TS -> Cores
	output		reg	[`CORES_RANGE]		Init_R0_Vect,			//TS -> Cores
	output  	reg	[`REG_BUS_RANGE]	Init_R0				//TS -> Cores
);


reg	[`TM_DEPTH_RANGE]	Task_Memory [`TM_WIDTH_RANGE];
wire 	[`TM_WIDTH_RANGE]	Task_Memory_Frame;

reg	[`IF_NUM_RANGE]		Task_Pointer;	
reg	[`IF_NUM_RANGE]		Insn_Frame_Num;
wire	[`CORES_RANGE]		EXEC_MASK;


reg 	[1:0]			fence;							//for Control Frame
reg 	[`CORES_RANGE]		Core_Active_Vect;


assign Task_Memory_Frame = Task_Memory[Task_Pointer];

genvar ii;
generate for (ii = 0; ii < `NUM_OF_CORES; ii = ii + 1) begin: exec_mask_loop
	assign EXEC_MASK[ii] = ~Ready[ii];
end
endgenerate

generate for (ii = 0; ii < `TASK_MEM_DEPTH; ii = ii + 1) begin: init_TM_loop
	always @(posedge clk)								//TM from Env
		if (Task_Pointer == `TASK_MEM_DEPTH - 1)
			Task_Memory[ii] <= env_task_memory[ii];
end
endgenerate



always @(posedge clk)									//Start
	Start <= (~reset & Insn_Frame_Num)? Core_Active_Vect : 0;
	

always @(posedge clk)									//Insn Data
begin
	if (reset)
		Insn_Data <= 0;
	if (~reset & Insn_Frame_Num) 
		Insn_Data <= Task_Memory_Frame;
end

always @(posedge clk)									//Init_R0_Vect
begin
	if (reset)
		{Init_R0, Init_R0_Vect} <= 0;

	if (~reset & Insn_Frame_Num == 0)
		Init_R0_Vect <= Task_Memory_Frame[`R0_VECT_RANGE]; 
end

generate for (ii = `NUM_OF_CORES - 1; ii >= 0; ii = ii - 1) begin: init_R0_loop		//Init_R0
	always @(posedge clk)
		if (~reset & Insn_Frame_Num == 0) begin
			Init_R0[`R0_RANGE(ii)] <= Task_Memory_Frame[`TM_R0_RANGE(ii)];
		end
end
endgenerate


always @(posedge clk)									//Instruction Frame Num
begin
	if (reset)
		Insn_Frame_Num 	<= 0;
	else begin
		if ( (Core_Active_Vect & EXEC_MASK) == 0 & Insn_Frame_Num)				
			Insn_Frame_Num	 <= Insn_Frame_Num - 1;		

		if ( (Insn_Frame_Num == 0 & (fence == `ACQ | `FENCE_NEXT == `REL) & EXEC_MASK == 0) |
			     (  fence == `NO & (EXEC_MASK & `CORE_ACTIVE_VECT_NEXT) == 0) )
			Insn_Frame_Num   <= Task_Memory_Frame[`IF_NUM_RANGE];
	end	
end

always @(posedge clk)
begin
	if ( (~reset & Insn_Frame_Num == 0) & ( (fence == `ACQ | `FENCE_NEXT == `REL) & EXEC_MASK == 0) |
			     (  fence == `NO & (EXEC_MASK & `CORE_ACTIVE_VECT_NEXT) == 0) )
		Core_Active_Vect <= `CORE_ACTIVE_VECT_NEXT;
end

always @(posedge clk)									//Task Pointer
begin
	if (reset)
		Task_Pointer <= 0;
	else begin
		if ((Core_Active_Vect & EXEC_MASK) == 0 & Insn_Frame_Num)
			Task_Pointer	<= Task_Pointer   + 1;

		if ( Insn_Frame_Num == 0 & ( ((fence == `ACQ | `FENCE_NEXT == `REL) & EXEC_MASK == 0) |
			     		     (fence == `NO & (EXEC_MASK & `CORE_ACTIVE_VECT_NEXT) == 0) ) )
			Task_Pointer	<= Task_Pointer + 1;

	end
end


always @(posedge clk)									//fence
begin
	if (reset)
		fence <= `NO;
	else if ( Insn_Frame_Num == 0 & ( ((fence == `ACQ | `FENCE_NEXT == `REL) & EXEC_MASK == 0) |
			     		   (fence == `NO & (EXEC_MASK & `CORE_ACTIVE_VECT_NEXT) == 0) ) )
		fence <= Task_Memory_Frame[`TS_FENCE_RANGE];
end

endmodule