`ifndef CONSTANTS
`define CONSTANTS

`define	NUM_OF_CORES 16
`define	CORES_RANGE (`NUM_OF_CORES - 1) : (0)
`define CORE_ID_SIZE 4
`define CORE_ID_RANGE (`CORE_ID_SIZE - 1) : (0)

`define REG_COUNT 16
`define REG_PTR_SIZE 4
`define REG_PTR_RANGE (`REG_PTR_SIZE - 1) : (0)
`define REG_SIZE 8
`define REG_RANGE (`REG_SIZE - 1) : (0)

`define ADDR_SIZE 12
`define ADDR_RANGE (`ADDR_SIZE - 1) : (0)

`define INSN_COUNT 16
`define INSN_SIZE 16
`define INSN_RANGE (`INSN_SIZE - 1) : (0)
`define INSN_BUS_COUNT 4
`define INSN_BUS_RANGE (`INSN_BUS_COUNT * `INSN_SIZE - 1) : (0)
`define INSN_LOAD_TIME 4
`define INSN_LOAD_COUNTER_SIZE 2
`define INSN_LOAD_COUNTER_RANGE (`INSN_LOAD_COUNTER_SIZE - 1) : (0)

`define INSN_PTR_SIZE 4
`define INSN_PTR_RANGE (`INSN_PTR_SIZE - 1) : (0)
`define INSN_OPC_SIZE 4
`define INSN_OPC_OFFSET 12
`define INSN_OPC_OFFSET_RANGE (`INSN_OPC_SIZE + `INSN_OPC_OFFSET - 1) : (`INSN_OPC_OFFSET)
`define INSN_OPC_RANGE (`INSN_OPC_SIZE - 1) : (0)
`define INSN_SRC_0_SIZE `REG_PTR_SIZE
`define INSN_SRC_0_OFFSET 8
`define INSN_SRC_0_OFFSET_RANGE (`INSN_SRC_0_SIZE + `INSN_SRC_0_OFFSET - 1) : (`INSN_SRC_0_OFFSET)
`define INSN_SRC_0_RANGE (`INSN_SRC_0_SIZE - 1) : (0)
`define INSN_SRC_1_SIZE `REG_PTR_SIZE
`define INSN_SRC_1_OFFSET 4
`define INSN_SRC_1_OFFSET_RANGE (`INSN_SRC_1_SIZE + `INSN_SRC_1_OFFSET - 1) : (`INSN_SRC_1_OFFSET)
`define INSN_SRC_1_RANGE (`INSN_SRC_1_SIZE - 1) : (0)
`define INSN_SRC_2_SIZE `REG_PTR_SIZE
`define INSN_SRC_2_OFFSET 0
`define INSN_SRC_2_OFFSET_RANGE (`INSN_SRC_2_SIZE + `INSN_SRC_2_OFFSET - 1) : (`INSN_SRC_2_OFFSET)
`define INSN_SRC_2_RANGE (`INSN_SRC_2_SIZE - 1) : (0)
`define INSN_DST_SIZE `REG_PTR_SIZE
`define INSN_DST_OFFSET 0
`define INSN_DST_OFFSET_RANGE (`INSN_DST_SIZE + `INSN_DST_OFFSET - 1) : (`INSN_DST_OFFSET)
`define INSN_DST_RANGE (`INSN_DST_SIZE - 1) : (0)
`define INSN_CONST_SIZE `REG_SIZE
`define INSN_CONST_OFFSET 4
`define INSN_CONST_OFFSET_RANGE (`INSN_CONST_SIZE + `INSN_CONST_OFFSET - 1) : (`INSN_CONST_OFFSET)
`define INSN_CONST_RANGE (`INSN_CONST_SIZE - 1) : (0)
`define INSN_TARGET_SIZE `INSN_PTR_SIZE
`define INSN_TARGET_OFFSET 4
`define INSN_TARGET_OFFSET_RANGE (`INSN_TARGET_SIZE + `INSN_TARGET_OFFSET - 1) : (`INSN_TARGET_OFFSET)
`define INSN_TARGET_RANGE (`INSN_TARGET_SIZE - 1) : (0)

`define FENCE_SIZE 2
`define FENCE_RANGE (`FENCE_SIZE - 1) : (0)

`define	BANK_DATA_SIZE 256
`define	BANK_DATA_RANGE (`BANK_DATA_SIZE - 1) : (0)
`define	NUM_OF_BANKS 16
`define	BANKS_RANGE (`NUM_OF_BANKS - 1) : (0)
`define BANK_ID_SIZE 4
`define BANK_ID_RANGE (`BANK_ID_SIZE - 1) : (0)

`define ADDR_BUS_RANGE (`ADDR_SIZE * `NUM_OF_CORES - 1) : (0)
`define	REG_BUS_RANGE (`REG_SIZE * `NUM_OF_CORES - 1) : (0)
`define ENABLE_SIZE 2
`define ENABLE_BUS_RANGE (`ENABLE_SIZE * `NUM_OF_CORES - 1) : (0)
`define ENABLE_RANGE (`ENABLE_SIZE - 1) : (0)

`define TASK_MEM_DEPTH	64
`define TASK_MEM_WIDTH	`INSN_LOAD_TIME * `INSN_BUS_COUNT * `INSN_SIZE

`define SIZE_IF_NUM	$clog2(`TASK_MEM_DEPTH)
`define IF_NUM_RANGE	(`SIZE_IF_NUM - 1) : (0)
`define TM_INSN_RANGE(jj)	((jj + 1) * `INSN_SIZE - 1) : (jj * `INSN_SIZE)
`define TM_PART_RANGE(jj) ((jj + 1) * `INSN_BUS_COUNT * `INSN_SIZE - 1) : (jj * `INSN_BUS_COUNT * `INSN_SIZE)
`define TS_FENCE_RANGE	(`SIZE_IF_NUM + 1) : (`SIZE_IF_NUM)

`define TM_DEPTH_RANGE (`TASK_MEM_DEPTH - 1) : (0)
`define TM_WIDTH_RANGE (`TASK_MEM_WIDTH - 1) : (0)
`define TM_RANGE       (`TASK_MEM_DEPTH * `TASK_MEM_WIDTH - 1) : (0)

`define R0_RANGE(jj)	(jj * `REG_SIZE + `REG_SIZE - 1) : (jj * `REG_SIZE)
`define TM_R0_RANGE(jj)									\
	(`TASK_MEM_WIDTH - `REG_SIZE * (`NUM_OF_CORES - jj) + `REG_SIZE - 1) : 		\
	(`TASK_MEM_WIDTH - `REG_SIZE * (`NUM_OF_CORES - jj))

`define ENV_TASK_MEMORY_RANGE(jj)							\
	(jj * `TASK_MEM_WIDTH + `TASK_MEM_WIDTH - 1) : (jj * `TASK_MEM_WIDTH)

`define STOP_BIT_RANGE (14) : (14)
`define STOP_ADDR_RANGE (13) : (8)

`define BIG_TACT_LENGTH 833334                      //[50000000Hz/60Hz]+1 
`define BIG_TACT_SIZE $clog2(`BIG_TACT_LENGTH)
`define VGA_DIV_RANGE (`BIG_TACT_SIZE - 1) : (0)

`endif //CONSTANTS
