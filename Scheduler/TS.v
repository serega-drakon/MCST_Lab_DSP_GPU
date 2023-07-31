module Task_Scheduler
#(
	parameter CORES_COUNT		= 16,
	parameter TASK_MEM_DEPTH	= 64,
	parameter TASK_MEM_WIDTH	= 256,

	parameter INSN_COUNT  		= 16,
	parameter INSN_SIZE  		= 16,
	parameter REG_SIZE 		= 8
)
(
	input	wire					clk,		//TS <- Env
	input	wire					rst,		//TS <- Env
	//input	wire	[CORES_COUNT * INSN_SIZE * INSN_COUNT - 1:0]	
	//						task_memory,	//TS <- Env 
									//todo: update data in TM


	input	wire	[CORES_COUNT -1:0]		Ready,		//TS <- Cores
	output  wire	[CORES_COUNT -1:0]		Start,		//TS -> Cores
	output	reg	[INSN_COUNT * INSN_SIZE - 1:0]	Insn_Data,	//TS -> Cores
	output  reg	[CORES_COUNT -1:0]		Init_R0_Vect,	//TS -> Cores
	output  reg	[CORES_COUNT * REG_SIZE - 1:0]	Init_R0		//TS -> Cores
);


reg [TASK_MEM_DEPTH :0]	Task_Memory [TASK_MEM_WIDTH - 1:0];

reg [5:0]		Task_Pointer;	
reg [CORES_COUNT - 1:0]	EXEC_MASK;
reg [5:0]		Insn_Frame_Num;


reg [15:0]		Header;						//for Control Frame
reg [15:0]		Core_Active_Vect;

assign Start = Core_Active_Vect;					//todo: fence


always @(posedge clk)
	EXEC_MASK <= (rst)? 0 : ~Ready;

always @(posedge clk)
begin
	if (rst)
		Insn_Data	<= 0;

	if (~rst & Insn_Frame_Num)
		Insn_Data <= Task_Memory[Task_Pointer];
end


always @(posedge clk)							//Control Frame
begin
	if (rst)
		Insn_Frame_Num <= 0;
	
	if (~Insn_Frame_Num & ~rst) begin
//		Header <= Task_Memory[Task_Pointer][0];
		Insn_Frame_Num   <= Task_Memory[Task_Pointer][5 : 0];
		Core_Active_Vect <= Task_Memory[Task_Pointer][2 * 16 - 1 : 1 * 16];	
	end else
		Insn_Frame_Num	 <= Insn_Frame_Num - 1;		
		
end


always @(posedge clk)							//Init_R0_Vect
begin
	if (rst)
		{Init_R0, Init_R0_Vect} <= 0;


	if (~Insn_Frame_Num & ~rst) begin
		Init_R0_Vect <= Task_Memory[Task_Pointer][3 * 16 - 1 : 2 * 16]; 
	end
end

genvar ii;
generate for (ii = CORES_COUNT - 1; ii >= 0; ii = ii - 1)		//Init_R0
	always @(posedge clk)
		if (~Insn_Frame_Num & ~rst) begin
			Init_R0[ii * REG_SIZE + REG_SIZE - 1 : ii * REG_SIZE] <= Task_Memory
			[Task_Pointer][TASK_MEM_WIDTH - REG_SIZE * (CORES_COUNT - ii) + REG_SIZE - 1: 
				       TASK_MEM_WIDTH - REG_SIZE * (CORES_COUNT - ii)];
		end
endgenerate


always @(posedge clk)							//Task_Pointer
	if (rst) begin
		Task_Pointer	     <= 0;
	end else
		if (~EXEC_MASK)						//todo: fence
			Task_Pointer <= Task_Pointer + 1;


endmodule
