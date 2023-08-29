`include"../SharedInc/IncAll.def.v"

module find_id_core
(
	input	wire	[`CORES_RANGE]		mask,
	input	wire	[`CORE_ID_RANGE]	start_search,
	output 	wire	[`CORE_ID_SIZE:0]	result
);

wire	[`CORE_ID_RANGE]	value	[`NUM_OF_CORES:0];

assign result[`CORE_ID_SIZE] = (mask == `NUM_OF_CORES'h0);
assign result[`CORE_ID_RANGE] = (result[`CORE_ID_SIZE]) ? start_search : value[0];

genvar i;
generate for(i = `NUM_OF_CORES - 1; i >= 0; i = i - 1)
begin: loop
	assign value[i] =
		((i < `NUM_OF_CORES - start_search - 1) ? (mask[start_search + 1 + i]) :
			(mask[i - `NUM_OF_CORES + start_search + 1])) ?
			((start_search + i + 1 < `NUM_OF_CORES) ? (start_search + i + 1) :
				(start_search - `NUM_OF_CORES + i + 1)) : value[i + 1];
end
endgenerate

endmodule
