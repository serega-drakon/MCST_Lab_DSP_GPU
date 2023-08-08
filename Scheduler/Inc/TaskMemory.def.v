`ifndef TASK_MEMORY
`define TASK_MEMORY

`define NO  4'h0		//no fence
`define ACQ 4'h1		//acquire
`define REL 4'h2		//release
`define RSV 4'h3		//reserve

`define TASK_MEM_DEPTH	64
`define TASK_MEM_WIDTH	256

`endif //TASK_MEMORY