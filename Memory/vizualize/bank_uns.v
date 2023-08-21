`include"../SharedInc/IncAll.def.v"

`define FILE "input.txt"

module bank_uns #(
	parameter BANK_ID = 0
)(
	input 				clk,
	input 				reset,
	input		[`REG_RANGE]	addr,
	input		[`REG_RANGE]	data_in,
	input				read_enable,
	input				write_enable,
	output	wire	[`REG_RANGE]	data_out,
	input	wire			dump
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
end

integer f;
integer i;
integer j;

always @(posedge dump)
begin
	if(~reset)
	begin
		f = $fopen($sformatf("test_data/bank%2d.txt", BANK_ID),"w");
		for(j = 0; j < 4; j = j + 1) begin
			for(i = 0; i < 64; i = i + 1)
				$fwrite(f,"%h ", memory[i + j * 64]);
			$fwrite(f,"\n");
		end
		$fclose(f);
	end
end

endmodule
