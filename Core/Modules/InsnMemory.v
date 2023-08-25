`include "IncAllCore.def.v"

module InsnMemory (
    input wire clk,
    input wire reset,

    input wire init_insn_mem, // Start&Ready
    input wire [`INSN_BUS_RANGE] insn_data,
    input wire [`INSN_PTR_RANGE] insn_ptr,
    input wire [`INSN_LOAD_COUNTER_RANGE] insn_load_counter,
    output wire [`INSN_SIZE - 1 : 0] insn_curr
);
    reg [`INSN_SIZE - 1 : 0] insn_mem_r[`INSN_COUNT - 1 : 0];

    assign insn_curr = insn_mem_r[insn_ptr];

    generate
        for(genvar i = 0; i < `INSN_LOAD_TIME; i = i + 1)
        for(genvar j = 0; j < `INSN_BUS_COUNT; j = j + 1) begin : insn_mem_loop
            always @(posedge clk)
                insn_mem_r[j + i * `INSN_BUS_COUNT] <=
                    (~reset & init_insn_mem & insn_load_counter == i) ?
                        insn_data[(j + 1) * `INSN_SIZE - 1 : j * `INSN_SIZE] :
                        insn_mem_r[j + i * `INSN_BUS_COUNT];
        end
    endgenerate

endmodule