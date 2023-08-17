`include"../SharedInc/IncAll.def.v"

`define FILE "input.txt"

module bank_uns
(
	input 				clk,
	input 				reset,
	input		[`REG_RANGE]	addr,
	input		[`REG_RANGE]	data_in,
	input				read_enable,
	input				write_enable,
	output	wire	[`REG_RANGE]	data_out,
	input	wire			dump,
	input	wire	[31:0]		id_bank
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
begin
	if(~reset)
		memory[addr] <= (write_enable) ? data_in : memory[addr];
	else
		memory[addr] <= `REG_SIZE'h0;
end

integer f;
integer i;

always @(posedge dump)
begin
	if(~reset)
	begin
		f = $fopen(`FILE,"ab");
		for( i = 0; i < 64; i = i + 1)
			$fwrite(f,"%h ", memory[i]);
		$fwrite(f,"\n");
		for( i = 64; i < 128; i = i + 1)
			$fwrite(f,"%h ", memory[i]);
		$fwrite(f,"\n");
		for( i = 128; i < 192; i = i + 1)
			$fwrite(f,"%h ", memory[i]);
		$fwrite(f,"\n");
		for( i = 192; i < 256; i = i + 1)
			$fwrite(f,"%h ", memory[i]);
		$fwrite(f,"\n");
		$fclose(f);
	end
end

endmodule
