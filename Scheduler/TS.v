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

reg	[`IF_NUM_RANGE]		Task_Pointer;	
reg	[`IF_NUM_RANGE]		Insn_Frame_Num;
reg	[`CORES_RANGE]		EXEC_MASK;


reg 	[1:0]			fence;							//for Control Frame
reg 	[`CORES_RANGE]		Core_Active_Vect;


genvar ii;
generate for (ii = 0; ii < `TASK_MEM_DEPTH; ii = ii + 1) begin: init_TM_loop
	always @(posedge clk)								//TM from Env
		if (Task_Pointer == `TASK_MEM_DEPTH - 1)
			Task_Memory[ii] <= env_task_memory[ii];
end
endgenerate

always @(posedge clk)									//Insn Data
begin
	if (reset) begin
		Insn_Data	<= 0;
		Start		<= 0;
	end

	if (~reset & Insn_Frame_Num) begin
		Insn_Data <= Task_Memory[Task_Pointer];
		Start <= Core_Active_Vect;
	end
	
	if (~Insn_Frame_Num)
		Start <= 0;
end


always @(posedge clk)									//Init_R0_Vect
begin
	if (reset)
		{Init_R0, Init_R0_Vect} <= 0;


	if (~Insn_Frame_Num & ~reset) begin
		Init_R0_Vect <= Task_Memory[Task_Pointer][`R0_VECT_RANGE]; 
	end
end

genvar jj;
generate for (jj = `NUM_OF_CORES - 1; jj >= 0; jj = jj - 1) begin: init_R0_loop		//Init_R0
	always @(posedge clk)
		if (~Insn_Frame_Num & ~reset) begin
			Init_R0[`R0_RANGE(jj)] <= Task_Memory[Task_Pointer][`TM_R0_RANGE(jj)];
		end
end
endgenerate


assign EXEC_MASK = ~Ready;


always @(posedge clk)									//Control Frame
begin
	if (reset) begin
		Task_Pointer 	<= 0;
		Insn_Frame_Num 	<= 0;
		fence 		<= `NO;
	end else begin
		if ((Core_Active_Vect & Ready == Core_Active_Vect) & Insn_Frame_Num) begin				
			Insn_Frame_Num	 <= Insn_Frame_Num - 1;		
			Task_Pointer	 <= Task_Pointer   + 1;
		end



		if (~Insn_Frame_Num) begin
			if ( ( (fence == `REL | `FENCE_NEXT == `ACQ) & ~EXEC_MASK    ) |
			     (  fence == `NO & ~(EXEC_MASK & `CORE_ACTIVE_VECT_NEXT) ) )
			begin
				Insn_Frame_Num   <= Task_Memory[Task_Pointer][`IF_NUM_RANGE];
				fence		 <= Task_Memory[Task_Pointer][`TS_FENCE_RANGE];
				Core_Active_Vect <= `CORE_ACTIVE_VECT_NEXT;
				Task_Pointer 	 <= Task_Pointer + 1;
			end
		end
	end	
end

endmodule