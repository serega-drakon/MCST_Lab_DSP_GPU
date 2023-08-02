`include "Inc/Constants.vh"

module InsnMemory #(
    parameter INSN_COUNT = `INSN_COUNT,
    parameter INSN_SIZE = `INSN_SIZE,
    parameter INSN_PTR_SIZE = `INSN_PTR_SIZE
)(
    input wire clk,
    input wire reset,

    input wire init_insn_mem, // Start&Ready
    input wire [INSN_COUNT * INSN_SIZE - 1 : 0] insn_data,
    input wire [INSN_PTR_SIZE - 1 : 0] insn_ptr,
    output wire [INSN_SIZE - 1 : 0] insn_curr
);
    reg [INSN_SIZE - 1 : 0] insn_mem [INSN_COUNT - 1 : 0];

    assign insn_curr = insn_mem[insn_ptr];

    generate for(genvar i = 0; i < INSN_COUNT; i = i + 1) begin : insn_mem_loop
        always @(posedge clk)
            if(~reset)
                insn_mem[i][INSN_SIZE - 1 : 0] = (init_insn_mem) ?
                    insn_data[(i + 1) * INSN_SIZE - 1 : i * INSN_SIZE] :
                    insn_mem[i][INSN_SIZE - 1 : 0];
    end
    endgenerate

endmodule