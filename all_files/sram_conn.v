`include "IncAllTest.def.v"

module sram_conn(
	input	wire			clk,
	input 	wire			rst,

	input 	wire			write,
	input 	wire			read,
	input	wire	[1:0]		byte_en,
	input 	wire	[`ADDR_RANGE]		addr,
	input 	wire	[`REG_RANGE]		data_in,
	output 	reg	[`REG_RANGE]		data_out,

	inout 	wire	[15:0]		sram_data,
	output 		[19:0]		sram_addr,
	output 				sram_ce_n,
	output 				sram_oe_n,
	output 				sram_we_n,
	output 				sram_ub_n,
	output 				sram_lb_n
);

parameter [15:0] h_imp = 16'bzzzzzzzzzzzzzzzz;
parameter [7:0] h_imp_half = 8'bzzzzzzzz;

//assign	sram_data = write ? data_in : 16'bz;
assign	sram_addr = {8'b0,addr};
assign	sram_ce_n = ~(write | read);
assign	sram_we_n = ~write;
assign	sram_oe_n = ~read;
assign	sram_ub_n = ~(byte_en[1]);
assign	sram_lb_n = ~(byte_en[0]);

assign sram_data[7:0] = ((~byte_en[0]) | (sram_ce_n)) ? h_imp_half:
			(write) ? data_in : h_imp_half;
assign sram_data[15:8] = ((~byte_en[1]) | (sram_ce_n)) ? h_imp_half:
			 (write) ? 8'b00000000 : h_imp_half;

always @(posedge clk)
begin
	data_out <= (rst) ? 0 : (read) ? sram_data[7:0] : data_out;
end

endmodule
/*always @(posedge clk)
begin
	if(byte_en == 2'b00)
	begin
		sram_data <= h_imp;
	end
	if(write | read)
	begin
		if(write)
		begin
			sram_data[7:0] <= (byte_en[0]) ? data_in : h_imp_half;
			sram_data[15:8] <= (byte_en[1]) ? 8'b00000000 : h_imp_half;
		end
		if(read)
		begin
			data_out <= sram_data[7:0];
			sram_data[15:8] <= h_imp_half;
		end
	end
	else
	begin
		sram_data <= h_imp;
	end
	if(sram_ce_n)
	begin
		sram_data <= h_imp;
	end
end*/
