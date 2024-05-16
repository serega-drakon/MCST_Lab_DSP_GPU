`include "Ranges.def.v"
`include "Fence.def.v"

module Task_Scheduler
	(
		input       wire                               clk,                  //TS <- Env
		input       wire                               reset,                //TS <- Env
		input       wire    [`TM_RANGE]                env_task_memory,      //TS <- Env
		input       wire    [`CORES_RANGE]             Ready,                //TS <- Cores
		output      wire    [`CORES_RANGE]             Start,                //TS -> Cores
		output      wire    [`INSN_LOAD_COUNTER_RANGE] Insn_Load_Counter,    //TS -> Cores
		output      wire    [`INSN_BUS_RANGE]          Insn_Data,            //TS -> Cores
		output      reg     [`CORES_RANGE]             Init_R0_Vect,         //TS -> Cores
		output      reg     [`REG_BUS_RANGE]           Init_R0,              //TS -> Cores

		input       wire                               vga_end,              //TS <- VGA
		output      reg                                vga_en                //TS -> VGA 
	);

 	wire    [`TM_WIDTH_RANGE]      Task_Memory [`TM_DEPTH_RANGE];
	wire    [`TM_WIDTH_RANGE]      Task_Memory_Frame;

	reg     [`IF_NUM_RANGE]        Task_Pointer;
	reg     [`IF_NUM_RANGE]        Insn_Frame_Num;
	wire    [`CORES_RANGE]         EXEC_MASK;

	reg     [`FENCE_RANGE]         fence;           //for Control Frame

	reg     [`CORES_RANGE]         Core_Active_Vect;
	wire    [`CORES_RANGE]         CORE_ACTIVE_VECT_NEXT;
	wire    [`FENCE_RANGE]         FENCE_NEXT;

	wire                           FLAG_TIME;       //wait cores [CF -> 1 cycle, IF ->(INSN LOAD TIME) cycles]
	reg	[`INSN_LOAD_COUNTER_RANGE] INSN_LOAD_CNT;   //wait cores >(INSN LOAD TIME) cycles

	reg                            stop_r;
	reg     [`IF_NUM_RANGE]        stop_addr_r;
	
	reg     [`VGA_DIV_RANGE]       vga_div_50MHz_60Hz;

	assign Task_Memory_Frame     = Task_Memory[Task_Pointer];

	assign FENCE_NEXT            = Task_Memory_Frame[`TS_FENCE_RANGE];
	assign CORE_ACTIVE_VECT_NEXT = Task_Memory_Frame[`TM_INSN_RANGE(1)];

	assign Insn_Load_Counter     = INSN_LOAD_CNT;

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

	wire exec_block_cond    = fence == `ACQ | FENCE_NEXT == `REL;
	wire insn_finish        = (EXEC_MASK & Core_Active_Vect) == 0;
	wire insn_freeee        = (EXEC_MASK & CORE_ACTIVE_VECT_NEXT) == 0;

	wire insn_free_no_fence = (insn_freeee & fence == `NO);


	assign Insn_Data = Task_Memory_Frame_Part[INSN_LOAD_CNT];

	wire start_cond  = (Insn_Frame_Num != 0 & insn_finish);                              //maybe & ~stop_r; 

	assign Start     =
		(start_cond) ? Core_Active_Vect : 0;

	wire STOP_NEXT                      = Task_Memory_Frame[`STOP_BIT_RANGE];
	wire [`IF_NUM_RANGE] STOP_ADDR_NEXT = Task_Memory_Frame[`STOP_ADDR_RANGE];

	assign FLAG_TIME = (INSN_LOAD_CNT == `INSN_LOAD_TIME - 1);

	reg vga_wait;

	//wire vga_wait_do = Insn_Frame_Num == 0 & EXEC_MASK == 0 & stop_r & ~vga_wait;   //походу тут лажа
	wire vga_wait_do = Insn_Frame_Num == 0 & EXEC_MASK == 0 & stop_r;
	//wire vga_wait_do =  Insn_Frame_Num == 0 & (vga_div_50MHz_60Hz == `BIG_TACT_LENGTH - 1) & stop_r & insn_finish & ~vga_en;
	wire vga_stop = vga_wait;
		
		
		
	reg vga_end_prev;
		
	always @(posedge clk)
		vga_end_prev <= vga_end;
	
	always @(posedge clk)
		vga_wait <= (reset)             ? 0 :
                    (vga_wait_do)       ? 1 :
                    (vga_end & ~vga_en & ~vga_end_prev & vga_wait) ? 0 : vga_wait;

	always @(posedge clk)
		vga_en <= (reset) ? 0 :
			((vga_div_50MHz_60Hz == `BIG_TACT_LENGTH - 1) & (insn_finish)) ? 1 : 0;

	
	always @(posedge clk)
			vga_div_50MHz_60Hz <= (reset)                                     ? 0                      : 
			                      (vga_div_50MHz_60Hz < `BIG_TACT_LENGTH - 1) ? vga_div_50MHz_60Hz + 1 : 0;
					  	

    always @(posedge clk)
        stop_r <= (reset)               ? 0         :
                  (Insn_Frame_Num == 0) ? STOP_NEXT : 
				                          stop_r;

	always @(posedge clk)
		stop_addr_r <= (Insn_Frame_Num == 0) ? STOP_ADDR_NEXT : stop_addr_r;

	always @(posedge clk)
		Init_R0_Vect <= (reset) ? 0 :
			(Insn_Frame_Num == 0) ? Task_Memory_Frame[`TM_INSN_RANGE(2)] : Init_R0_Vect; //fix: const

	generate for (ii = `NUM_OF_CORES - 1; ii >= 0; ii = ii - 1) begin: init_R0_loop		 //Init_R0
		always @(posedge clk)
			Init_R0[`R0_RANGE(ii)] <= (reset) ? 0 :
				(Insn_Frame_Num == 0) ? Task_Memory_Frame[`TM_R0_RANGE(ii)] : Init_R0[`R0_RANGE(ii)];
	end
	endgenerate

	wire [`IF_NUM_RANGE] INSN_FRAME_NUM_NEXT = Task_Memory_Frame[`IF_NUM_RANGE];

      
	always @(posedge clk)
		Insn_Frame_Num <= (reset)    ? 0                   :
		                  (vga_stop) ? Insn_Frame_Num      :

            (FLAG_TIME & (Insn_Frame_Num > 1 & insn_finish
		        | Insn_Frame_Num == 1)) 
				                     ? Insn_Frame_Num - 1  :

				( Insn_Frame_Num == 0 & 
				((EXEC_MASK == 0 & exec_block_cond) |
				 insn_free_no_fence ) ) 
				                     ? INSN_FRAME_NUM_NEXT :
							           Insn_Frame_Num;


    wire core_active_vect_upd = Insn_Frame_Num == 0 &
			    ((EXEC_MASK == 0 & exec_block_cond) |
			   insn_free_no_fence);

    always @(posedge clk)
        Core_Active_Vect <= (reset) ? 0                     : 
                         (vga_stop) ? Core_Active_Vect      :
             (core_active_vect_upd) ? CORE_ACTIVE_VECT_NEXT :
			                          Core_Active_Vect ;


    wire insn_load_cnt_upd = start_cond;                    // >0 equiv !=0
    wire insn_load_cnt_end = (insn_load_cnt_upd & FLAG_TIME) |
				(Insn_Frame_Num == 0 & ( (EXEC_MASK == 0 & exec_block_cond) |
					                    insn_free_no_fence));


    always @(posedge clk)									//Instruction load counter
        begin
            INSN_LOAD_CNT <= (reset) ? 0                 :
                 (insn_load_cnt_end) ? 0                 : 
                 (insn_load_cnt_upd) ? INSN_LOAD_CNT + 1 :
                                       INSN_LOAD_CNT;
		end


	always @(posedge clk)									//Task Pointer
		begin
			if (reset)
				Task_Pointer <= 0;					        //initially TM is empty or old
				
			else if( (vga_stop) | 
					 (Insn_Frame_Num == 0 & INSN_FRAME_NUM_NEXT == 0 & STOP_NEXT) )
				Task_Pointer <= STOP_ADDR_NEXT;             //maybe Task_Pointer;
				
			else if(Insn_Frame_Num == 0 &
				   (EXEC_MASK == 0 & exec_block_cond |
					insn_free_no_fence))
				Task_Pointer <= Task_Pointer + 1;
				
			else if(Insn_Frame_Num == 1 & FLAG_TIME)
				Task_Pointer <= (stop_r) ? stop_addr_r : Task_Pointer + 1;
				
			else if(Insn_Frame_Num > 1 & FLAG_TIME & insn_finish)
				Task_Pointer <= Task_Pointer + 1;
				
			else 
			    Task_Pointer <= Task_Pointer;	
				
		end


    wire fence_upd = (Insn_Frame_Num == 0) &
		( (EXEC_MASK != 0 & exec_block_cond) | insn_free_no_fence );
    wire fence_end = (Insn_Frame_Num == 1) & stop_r;

    always @(posedge clk)									//fence
        begin
            fence <= (reset) ? `NO                                :
			     (vga_stop)  ? fence                              :
                 (fence_upd) ? Task_Memory_Frame[`TS_FENCE_RANGE] :
                 (fence_end) ? `ACQ                               :  //waiting for the end of the end))))
                               fence;
		end

endmodule