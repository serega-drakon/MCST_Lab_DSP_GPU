`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/TaskMemory.def.v"

module Task_Scheduler
#(
	parameter CORES_COUNT		= 16,

	parameter TASK_MEM_DEPTH	= `TASK_MEM_DEPTH,
	parameter TASK_MEM_WIDTH	= `TASK_MEM_WIDTH,

	parameter INSN_COUNT  		= `INSN_COUNT,
	parameter INSN_SIZE  		= `INSN_SIZE,
	parameter REG_SIZE 		= `REG_SIZE
)
(
	input	wire					clk,				//TS <- Env
	input	wire					reset,				//TS <- Env
	input	wire	[CORES_COUNT * INSN_SIZE * INSN_COUNT - 1:0]	
							env_task_memory,		//TS <- Env 


	input	wire	[CORES_COUNT -1:0]		Ready,				//TS <- Cores
	output  reg	[CORES_COUNT -1:0]		Start,				//TS -> Cores
	output	reg	[INSN_COUNT * INSN_SIZE -1:0]	Insn_Data,			//TS -> Cores
	output  reg	[CORES_COUNT -1:0]		Init_R0_Vect,			//TS -> Cores
	output  reg	[CORES_COUNT * REG_SIZE -1:0]	Init_R0				//TS -> Cores
);


reg [TASK_MEM_DEPTH :0]	Task_Memory [TASK_MEM_WIDTH - 1:0];

reg [5:0]		Task_Pointer;	
reg [CORES_COUNT - 1:0]	EXEC_MASK;
reg [5:0]		Insn_Frame_Num;


reg [1 :0]		Fence;								//for Control Frame
reg [15:0]		Core_Active_Vect;


genvar ii;
generate for (ii = 0; ii < TASK_MEM_DEPTH; ii = ii + 1) begin: init_TM_loop
	always @(posedge clk)								//TM from Env
		if (Task_Pointer == TASK_MEM_DEPTH)
			Task_Memory[ii] <= env_task_memory[ii];
end
endgenerate


always @(posedge clk)
	EXEC_MASK <= (reset)? 0 : ~Ready;

always @(posedge clk)
begin
	if (reset)
		Insn_Data	<= 0;

	if (~reset & Insn_Frame_Num)
		Insn_Data <= Task_Memory[Task_Pointer];
end


always @(posedge clk)									//Control Frame
begin
	if (reset)
		Insn_Frame_Num <= 0;
	
	if (~Insn_Frame_Num & ~reset) begin
		Insn_Frame_Num   <= Task_Memory[Task_Pointer][5 : 0];
		Fence		 <= Task_Memory[Task_Pointer][7 : 6];
		Core_Active_Vect <= Task_Memory[Task_Pointer][2 * 16 -1 : 1 * 16];	//[...+header, +header] todo
	end else
		Insn_Frame_Num	 <= Insn_Frame_Num - 1;		
		
end


always @(posedge clk)									//Init_R0_Vect
begin
	if (reset)
		{Init_R0, Init_R0_Vect} <= 0;


	if (~Insn_Frame_Num & ~reset) begin
		Init_R0_Vect <= Task_Memory[Task_Pointer][3 * 16 -1 : 2 * 16]; 
	end
end

always @(posedge clk)									//Start
begin
	Start <= (~reset & ~Insn_Frame_Num)? Core_Active_Vect : 0;
end


genvar jj;
generate for (jj = CORES_COUNT - 1; jj >= 0; jj = jj - 1) begin: init_R0_loop		//Init_R0
	always @(posedge clk)
		if (~Insn_Frame_Num & ~reset) begin
			Init_R0[jj * REG_SIZE + REG_SIZE - 1 : jj * REG_SIZE] <= Task_Memory
			[Task_Pointer][TASK_MEM_WIDTH - REG_SIZE * (CORES_COUNT - jj) + REG_SIZE -1: 
				       TASK_MEM_WIDTH - REG_SIZE * (CORES_COUNT - jj)];
		end
end
endgenerate


always @(posedge clk)									//Task_Pointer
begin
	if (reset)
		Task_Pointer <= 0;

	case (Fence)
		`NO: begin
			if (~EXEC_MASK & ~reset)					//todo: fence
				Task_Pointer <= Task_Pointer + 1;
		end

		`ACQ: begin

		end

		`REL: begin

		end

		`RSV: begin

		end
	endcase
end

endmodule
