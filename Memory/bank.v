module bank
(
	input 			clk,
	input 			reset,
	input		[7:0]	addr,
	input		[7:0]	data_in,
	input			read_enable,
	input			write_enable,
	output	wire	[7:0]	data_out,
	output	wire		valid_out
);

reg	[7:0]	memory	[255:0];
reg	[255:0]	mask_valid_data;

reg	[7:0]	read;
reg		valid;

assign	data_out = read;
assign	valid_out = valid;

always @(posedge clk)
begin
	if(reset)
	begin
		mask_valid_data <= 0;
	end
	else
	begin
		if(read_enable)
		begin
			read <= memory[addr];
			valid <= mask_valid_data[addr];
		end
		else 
			if(write_enable)
			begin
				memory[addr] <= data_in;
				mask_valid_data[addr] <= 1;
			end
	end
end

endmodule
