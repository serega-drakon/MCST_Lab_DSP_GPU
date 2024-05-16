`include "IncAllTest.def.v"

module sram_conn_debug(
	input	wire			clk,
	input 	wire			rst,
	input 	wire 			dump,

	input 	wire					write,
	input 	wire					read,
	input	wire	[1:0]			byte_en,
	input 	wire	[`ADDR_RANGE]	addr,
	input 	wire	[`REG_RANGE]	data_in,
	output 	reg		[`REG_RANGE]	data_out,

	inout  	wire	[15:0]		sram_data,
	output 			[19:0]		sram_addr,
	output 						sram_ce_n,
	output 						sram_oe_n,
	output 						sram_we_n,
	output 						sram_ub_n,
	output 						sram_lb_n
);

	parameter [15:0] h_imp = 16'bzzzzzzzzzzzzzzzz;
	parameter [7:0] h_imp_half = 8'bzzzzzzzz;

	//assign	sram_data = write ? data_in : 16'bz;
	assign	sram_addr = 1'bz;//{8'b0,addr};
	assign	sram_ce_n = 1'bz;//~(write | read);
	assign	sram_we_n = 1'bz;//~write;
	assign	sram_oe_n = 1'bz;//~read;
	assign	sram_ub_n = 1'bz;//~(byte_en[1]);
	assign	sram_lb_n = 1'bz;//~(byte_en[0]);

	assign sram_data[7:0] = 8'bzzzzzzzz;
		//((~byte_en[0]) | (sram_ce_n)) ? h_imp_half:
		//		(write) ? data_in : h_imp_half;
	assign sram_data[15:8] = 8'bzzzzzzzz;
		//((~byte_en[1]) | (sram_ce_n)) ? h_imp_half:
		//		 (write) ? 8'b00000000 : h_imp_half;
	
	localparam 			im_width	= 64;
	localparam 			im_height 	= 64;
	localparam 			dump_mem_size = im_width * im_height;
	reg 	[`REG_RANGE]	dump_mem 	[dump_mem_size - 1 : 0];
	
	always @(posedge clk)
	begin
		data_out <= (rst) ? 0 : (read) ? dump_mem[addr] : data_out;
	end

	//debug

	always @(posedge clk)
		dump_mem[addr] <= write ? data_in : dump_mem[addr];

	integer f;
	integer i,j;
	always @(posedge dump)
		begin
			f = $fopen($sformatf("test_data/sram_data_dump.txt"),"w");
			for(i = 0; i < im_height; i = i + 1)
			begin
				for(j = 0; j < im_width; j = j + 1)
					$fwrite(f,"%h ", dump_mem[j + i * 64]);
				$fwrite(f,"\n");
			end
			$fclose(f);
		end

endmodule


