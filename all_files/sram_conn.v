`include "IncAllTest.def.v"

module sram_conn(
	input	wire			clk,
	input 	wire			rst,

	input 	wire			write,
	input 	wire			read,
	input	wire	[1:0]		byte_en,
	input 	wire	[`ADDR_RANGE]	addr,
	input 	wire	[`REG_RANGE]	data_in,
	output 	reg	[`REG_RANGE]	data_out,

	inout 	wire	[15:0]		sram_data,
	output 		[19:0]		sram_addr,
	output 				sram_ce_n,
	output 				sram_oe_n,
	output 				sram_we_n,
	output 				sram_ub_n,
	output 				sram_lb_n
);

assign	sram_data = write ? data_in : sram_data;
assign	sram_addr = {{8{0}},addr};
assign	sram_ce_n = ~(write | read);
assign	sram_we_n = ~write;
assign	sram_oe_n = ~read;
assign	sram_ub_n = ~(byte_en[1]);
assign	sram_lb_n = ~(byte_en[0]);

always @(posedge clk)
begin
	data_out <= (rst | ~read) ? 0 : sram_data[`REG_RANGE];
end

endmodule
