`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"

module Task_Scheduler
(
	input		wire				clk,				//TS <- Env
	input		wire				reset,				//TS <- Env
	input		wire	[`TM_RANGE]		env_task_memory,		//TS <- Env 


	input		wire	[`CORES_RANGE]		Ready,				//TS <- Cores

	output		reg	[`CORES_RANGE]		Start,				//TS -> Cores
	output		reg	[`TM_WIDTH_RANGE]	Insn_Data,			//TS -> Cores
	output		reg	[`CORES_RANGE]		Init_R0_Vect,			//TS -> Cores
	output  	reg	[`REG_BUS_RANGE]	Init_R0				//TS -> Cores
);


reg	[`TM_WIDTH_RANGE]	Task_Memory [`TM_DEPTH_RANGE];
wire 	[`TM_WIDTH_RANGE]	Task_Memory_Frame;

reg	[`IF_NUM_RANGE]		Task_Pointer;	
reg	[`IF_NUM_RANGE]		Insn_Frame_Num;
wire	[`CORES_RANGE]		EXEC_MASK;

reg 	[1:0]			fence;							//for Control Frame
reg 	[`CORES_RANGE]		Core_Active_Vect;
wire	[`CORES_RANGE]		CORE_ACTIVE_VECT_NEXT;
wire	[1:0]			FENCE_NEXT;


assign Task_Memory_Frame	= Task_Memory[Task_Pointer];

assign FENCE_NEXT 		= Task_Memory_Frame[`TS_FENCE_RANGE];
assign CORE_ACTIVE_VECT_NEXT	= Task_Memory_Frame[`CORE_ACTIVE_VECT_RANGE];

genvar ii;
generate for (ii = 0; ii < `NUM_OF_CORES; ii = ii + 1) begin: exec_mask_loop
	assign EXEC_MASK[ii] = ~Ready[ii];
end
endgenerate

generate for (ii = 0; ii < `TASK_MEM_DEPTH; ii = ii + 1) begin: init_TM_loop
	always @(posedge clk)								//TM from Env
		if (Task_Pointer == `TASK_MEM_DEPTH - 1)
			Task_Memory[ii] <= env_task_memory[`ENV_TASK_MEMORY_RANGE(ii)];

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
		Insn_Frame_Num 	<= 1;							//-> to beginning
	else begin
		if ( (EXEC_MASK & Core_Active_Vect) == 0 & Insn_Frame_Num ) begin			
			Insn_Frame_Num <= Insn_Frame_Num - 1;		
			$display ("Insn_Frame_Num--");
		end

		if ( Insn_Frame_Num == 0 & 
			     ( (EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
			     ((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO) ) ) begin
			Insn_Frame_Num <= Task_Memory_Frame[`IF_NUM_RANGE];
			$display ("Insn_Frame_Num loaded");
		end
	end	
end

always @(posedge clk)
begin
	if (reset)
		Core_Active_Vect <= 0;
	else if ( Insn_Frame_Num == 0 & 
			( (EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
			((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence  == `NO) ) ) begin
		Core_Active_Vect <= CORE_ACTIVE_VECT_NEXT;
		$display ("CAV changed");
	end
end

always @(posedge clk)									//Task Pointer
begin
	if (reset)
		Task_Pointer <= `TASK_MEM_DEPTH - 1;					//initially TM is empty or old
	else begin
		if (Insn_Frame_Num & (EXEC_MASK & Core_Active_Vect) == 0) begin
			Task_Pointer	<= Task_Pointer   + 1;
			$display ("TP just changed");
		end

		if ( Insn_Frame_Num == 0 & 
				( (EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
			     	((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO) ) ) begin
			Task_Pointer	<= Task_Pointer + 1;
			$display("TP changed with fence");
		end
	end
end


always @(posedge clk)									//fence
begin
	if (reset)
		fence <= `NO;
	else if ( Insn_Frame_Num == 0 & (
				(EXEC_MASK & (fence == `ACQ | FENCE_NEXT == `REL)) |
			     	((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO) ) ) begin
		fence <= Task_Memory_Frame[`TS_FENCE_RANGE];
		$display ("Insn_Frame_Num = %d", Insn_Frame_Num);
		$display ("fence changed");
	end
end

endmodule