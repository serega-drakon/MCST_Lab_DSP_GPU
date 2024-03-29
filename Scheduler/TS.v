`include "../SharedInc/Ranges.def.v"
`include "../SharedInc/Fence.def.v"

module Task_Scheduler
	(
		input		wire				clk,				//TS <- Env
		input		wire				reset,				//TS <- Env
		input		wire	[`TM_RANGE]		env_task_memory,		//TS <- Env
		input		wire	[`CORES_RANGE]		Ready,				//TS <- Cores
		output		wire	[`CORES_RANGE]		Start,				//TS -> Cores
		output		wire	[`INSN_LOAD_COUNTER_RANGE] Insn_Load_Counter,		//TS -> Cores
		output		wire	[`INSN_BUS_RANGE]	Insn_Data,			//TS -> Cores
		output		reg	[`CORES_RANGE]		Init_R0_Vect,			//TS -> Cores
		output  	reg	[`REG_BUS_RANGE]	Init_R0,				//TS -> Cores

		output reg vga,
		input wire vga_en
	);

 	wire	[`TM_WIDTH_RANGE]	Task_Memory [`TM_DEPTH_RANGE];
	wire 	[`TM_WIDTH_RANGE]	Task_Memory_Frame;

	reg	[`IF_NUM_RANGE]		Task_Pointer;
	reg	[`IF_NUM_RANGE]		Insn_Frame_Num;
	wire	[`CORES_RANGE]		EXEC_MASK;

	reg 	[`FENCE_RANGE]		fence;							//for Control Frame

	reg 	[`CORES_RANGE]		Core_Active_Vect;
	wire	[`CORES_RANGE]		CORE_ACTIVE_VECT_NEXT;
	wire	[`FENCE_RANGE]		FENCE_NEXT;

	wire FLAG_TIME;						//wait cores [CF -> 1 cycle, IF ->(INSN LOAD TIME) cycles]
	reg	[`INSN_LOAD_COUNTER_RANGE] INSN_LOAD_CNT;					//wait cores >(INSN LOAD TIME) cycles

	reg stop_r;
	reg	[`IF_NUM_RANGE] stop_addr_r;

	assign Task_Memory_Frame	= Task_Memory[Task_Pointer];

	assign FENCE_NEXT 		= Task_Memory_Frame[`TS_FENCE_RANGE];
	assign CORE_ACTIVE_VECT_NEXT	= Task_Memory_Frame[`TM_INSN_RANGE(1)];

	assign Insn_Load_Counter 	= INSN_LOAD_CNT;

	genvar ii;
	generate for (ii = 0; ii < `NUM_OF_CORES; ii = ii + 1) begin: exec_mask_loop
		assign EXEC_MASK[ii] = ~Ready[ii];
	end
	endgenerate

	generate for (ii = 0; ii < `TASK_MEM_DEPTH; ii = ii + 1) begin: init_TM_loop
		assign Task_Memory[ii] = env_task_memory[`ENV_TASK_MEMORY_RANGE(ii)];
	end
	endgenerate

	wire [`INSN_BUS_RANGE] Task_Memory_Frame_Part [`INSN_LOAD_TIME - 1 : 0];

	generate for (ii = 0; ii < `INSN_LOAD_TIME; ii = ii + 1) begin: insn_data_loop		//Instruction data
		assign Task_Memory_Frame_Part[ii] = Task_Memory_Frame[`TM_PART_RANGE(ii)];
	end
	endgenerate

	assign Insn_Data = Task_Memory_Frame_Part[INSN_LOAD_CNT];

	assign Start =
		(Insn_Frame_Num != 0 & (EXEC_MASK & Core_Active_Vect) == 0) ?
			Core_Active_Vect : 0;

	wire STOP_NEXT = Task_Memory_Frame[`STOP_BIT_RANGE];
	wire [`IF_NUM_RANGE] STOP_ADDR_NEXT = Task_Memory_Frame[`STOP_ADDR_RANGE];

	assign FLAG_TIME = INSN_LOAD_CNT == `INSN_LOAD_TIME - 1;

	reg vga_wait;
	wire vga_stop;

	assign vga_stop = vga_wait; //todo

	always @(posedge clk)
		vga_wait <= (reset) ? 0 :
			(Insn_Frame_Num == 0 & stop_r & EXEC_MASK == 0 & ~vga_wait) ? 1 :
			(~vga_en & ~vga) ? 0 : vga_wait; //todo: не добавил функционал зацикливания на себе

	always @(posedge clk)
		vga <= (reset) ? 0 :
			(Insn_Frame_Num == 0 & stop_r & EXEC_MASK == 0 & ~vga_wait) ? 1 : 0;

	always @(posedge clk)
		stop_r <= (reset) ? 0 :
			(Insn_Frame_Num == 0) ? STOP_NEXT : stop_r;

	always @(posedge clk)
		stop_addr_r <= (Insn_Frame_Num == 0) ? STOP_ADDR_NEXT : stop_addr_r;

	always @(posedge clk)
		Init_R0_Vect <= (reset) ? 0 :
			(Insn_Frame_Num == 0) ? Task_Memory_Frame[`TM_INSN_RANGE(2)] : Init_R0_Vect; //fixme: const

	generate for (ii = `NUM_OF_CORES - 1; ii >= 0; ii = ii - 1) begin: init_R0_loop		//Init_R0
		always @(posedge clk)
			Init_R0[`R0_RANGE(ii)] <= (reset) ? 0 :
				(Insn_Frame_Num == 0) ? Task_Memory_Frame[`TM_R0_RANGE(ii)] : Init_R0[`R0_RANGE(ii)];
	end
	endgenerate

	wire [`IF_NUM_RANGE] INSN_FRAME_NUM_NEXT = Task_Memory_Frame[`IF_NUM_RANGE];

	always @(posedge clk)
		Insn_Frame_Num <= (reset) ? 0 :
			(vga_stop) ? Insn_Frame_Num :
			(FLAG_TIME & (Insn_Frame_Num > 1 & (EXEC_MASK & Core_Active_Vect) == 0
				| Insn_Frame_Num == 1)) ? Insn_Frame_Num - 1 :
				( Insn_Frame_Num == 0 & ((EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
					((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO) ) ) ?
					INSN_FRAME_NUM_NEXT : Insn_Frame_Num;

	always @(posedge clk)
		Core_Active_Vect <= (reset) ? 0 :
			(vga_stop) ? Core_Active_Vect :
			(Insn_Frame_Num == 0 &
			((EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
				((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence  == `NO))) ?
				CORE_ACTIVE_VECT_NEXT : Core_Active_Vect;

	//todo
	always @(posedge clk)									//Instruction load counter
		begin
			if (reset)
				INSN_LOAD_CNT <= 0;
			else if ((Insn_Frame_Num > 0 & FLAG_TIME & (EXEC_MASK & Core_Active_Vect) == 0) |
				(Insn_Frame_Num == 0 & ( (EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
					((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO))))
				INSN_LOAD_CNT <= 0;
			else if(Insn_Frame_Num != 0  & (EXEC_MASK & Core_Active_Vect) == 0)
				INSN_LOAD_CNT <= INSN_LOAD_CNT + 1;
		end

	always @(posedge clk)									//Task Pointer
		begin
			if (reset)
				Task_Pointer <= 0;					//initially TM is empty or old
			if(vga_stop)
				Task_Pointer <= Task_Pointer;
			else if (Insn_Frame_Num > 1 & FLAG_TIME &
				(EXEC_MASK & Core_Active_Vect) == 0)
				Task_Pointer <= Task_Pointer + 1;
			else if (Insn_Frame_Num == 1 & FLAG_TIME)
				Task_Pointer <= (stop_r) ? stop_addr_r: Task_Pointer + 1;
			else if(Insn_Frame_Num == 0 & INSN_FRAME_NUM_NEXT == 0 & STOP_NEXT)
				Task_Pointer <= STOP_ADDR_NEXT;
			else if (Insn_Frame_Num == 0 &
				(EXEC_MASK == 0 & (fence == `ACQ | FENCE_NEXT == `REL) |
					((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO)))
				Task_Pointer <= Task_Pointer + 1;
		end


	always @(posedge clk)									//fence
		begin
			if (reset)
				fence <= `NO;
			else if ( Insn_Frame_Num == 0 & (
				(EXEC_MASK != 0 & (fence == `ACQ | FENCE_NEXT == `REL)) |
					((EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0 & fence == `NO) ) )
				fence <= Task_Memory_Frame[`TS_FENCE_RANGE];
			else if (Insn_Frame_Num == 1 & stop_r)
				fence <= `ACQ;
		end

endmodule