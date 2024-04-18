`include "vga.v"
`include "IncAll.def.v"

module vga_machine(
	input           clk,
	input           rst,
	
	output          vga_clk,
	output          h_sync,
	output          v_sync,
	output          blank_n,
	output          sync_n,
	output wire 	[`REG_RANGE]	red_vga,
	output wire 	[`REG_RANGE]	green_vga,
	output wire 	[`REG_RANGE]	blue_vga,
	
	output wire	[`ADDR_RANGE]	vga_addr,
	input		[`REG_RANGE]	vga_data
);

wire	[9:0]	x;
wire	[9:0]	y;

vga vga_0(
	.clk(clk),
	.rst(rst),
	
	.vga_clk(vga_clk),
	.h_sync(h_sync),
	.v_sync(v_sync),
	.blank_n(blank_n),
	.sync_n(sync_n),
	.point_pos_x(x),
	.point_pos_y(y)
);

assign red_vga = vga_data;
assign green_vga = vga_data;
assign blue_vga = vga_data;

assign vga_addr = {y[9:5], x[9:3]};

endmodule