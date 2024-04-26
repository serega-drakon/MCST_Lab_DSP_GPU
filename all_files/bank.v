`include"IncAll.def.v"
module bank
(
	input 				clk,
	input 				reset,
	input		[`REG_RANGE]	addr,
	input		[`REG_RANGE]	data_in,
	input				read_enable,
	input				write_enable,
	output	wire	[`REG_RANGE]	data_out
);

reg	[`REG_RANGE]	memory	[`BANK_DATA_RANGE];

reg	[`REG_RANGE]	read_r;

assign	data_out = read_r;

always @(posedge clk)
begin
	if(~reset)
		read_r <= (read_enable) ? memory[addr] : `REG_SIZE'h0;
	else
		read_r <= `REG_SIZE'h0;
end

always @(posedge clk)
		memory[addr] <= (write_enable) ? data_in : memory[addr];

endmodule
