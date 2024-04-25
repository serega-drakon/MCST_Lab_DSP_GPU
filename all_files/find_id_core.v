`include"IncAll.def.v"

module find_id_core
(
	input	wire	[`CORES_RANGE]		mask,
	input	wire	[`CORE_ID_RANGE]	start_search,
	output 	wire	[`CORE_ID_SIZE:0]	result
);

wire	[`CORE_ID_RANGE]	value	[`NUM_OF_CORES:0];

assign value[0] = start_search;
assign result[`CORE_ID_SIZE] = (mask == `NUM_OF_CORES'h0);
assign result[`CORE_ID_RANGE] = (result[`CORE_ID_SIZE]) ? start_search : value[`NUM_OF_CORES];

wire	[`CORES_RANGE] 	switch_mask;

genvar i;
generate for(i = 0; i < `NUM_OF_CORES; i = i + 1)
begin: loop_switch
	assign switch_mask[i] = (start_search + i + 1 < `NUM_OF_CORES) ? mask[start_search + i + 1] : mask[start_search + i + 1 - `NUM_OF_CORES]; 
end
endgenerate

generate for(i = 1; i < `NUM_OF_CORES + 1; i = i + 1)
begin: loop
	assign value[i] = ((switch_mask[i - 1]) && (value[i - 1] == start_search)) ? (start_search + i) : value[i - 1];
end
endgenerate

endmodule
