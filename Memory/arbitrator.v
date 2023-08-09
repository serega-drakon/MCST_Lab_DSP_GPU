`include"../Core/Modules/Inc/Ranges.def.v"
`include"bank.v"
module arbitrator
(
	input	wire 				clk,
	input	wire				reset,
	input	wire	[`ENABLE_BUS_RANGE]	enable,
	input	wire	[`ADDR_BUS_RANGE]	addr,
	input	wire	[`REG_BUS_RANGE]	wr_data,
	output	wire	[`REG_BUS_RANGE]	rd_data,
	output	wire	[`CORES_RANGE]		ready
);

reg	[`CORE_ID_RANGE] 	id_last_core;
reg	[`BANK_ID_RANGE]	id_last_bank;
reg				last_request_rd;

wire	[1:0]		request_core	[`CORES_RANGE];
wire	[`REG_RANGE]	wr_data_core	[`CORES_RANGE];
wire	[`ADDR_RANGE]	addr_core	[`CORES_RANGE];
wire	[`REG_RANGE]	rd_data_core	[`CORES_RANGE];

wire				skip;
wire	[`CORE_ID_RANGE]	id_current_core;
wire	[`BANK_ID_RANGE]	bank_addr;
wire	[`REG_RANGE]		data_addr_core;

wire	[`REG_RANGE]		data_addr_bank	[`BANK_ID_RANGE];
wire	[`REG_RANGE]		wr_data_bank	[`BANK_ID_RANGE];
wire	[`BANK_ID_RANGE]	read_request_bank;
wire	[`BANK_ID_RANGE]	write_request_bank;
wire	[`CORE_ID_RANGE]	read_core;
wire	[`BANK_ID_RANGE]	rd_data_bank	[`BANK_ID_RANGE];

genvar id_core;
generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_request
	assign	request_core[id_core] = enable[id_core * 2 + 1: id_core * 2];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_wr_data
	assign	wr_data_core[id_core] = wr_data[(id_core + 1) * `REG_SIZE - 1: id_core * `REG_SIZE];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_rd_data
	assign	rd_data[(id_core + 1) * `REG_SIZE - 1: id_core * `REG_SIZE] = rd_data_core[id_core];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_addr
	assign	addr_core[id_core] = addr[(id_core + 1) * `ADDR_SIZE - 1: id_core * `ADDR_SIZE];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_ready
	assign	ready[id_core] = ((id_core == id_last_core) && (~skip));
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_rd_data_core
	assign	rd_data_core[id_core] = ((id_core == id_last_core) && (last_request_rd)) ? rd_data_bank[id_last_bank] : `REG_SIZE'h0;
end
endgenerate

function [`CORE_ID_SIZE:0]		find_id_core;	
	input [`CORE_ID_RANGE]		start_search;	
	input [`ENABLE_BUS_RANGE]	request_all;	
	input [`CORE_ID_RANGE]		iteration;	
begin
	if(iteration == `CORE_ID_SIZE'hf)
	begin
		find_id_core = {1'b1, start_search};
	end
	else if({request_all[(start_search + 1) * 2 + 1], request_all[(start_search + 1) * 2]} == 2'b00)
	begin
		find_id_core = find_id_core(start_search + 1, request_all, iteration + 1);
	end
	else
	begin
		find_id_core = start_search + 1;
	end
end
endfunction

assign	{skip, id_curent_core} = find_id_core(id_last_core, enable, 0);
assign	{bank_addr, data_addr_core} = addr_core[id_curent_core];

genvar id_bank;
generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
	begin
		assign	data_addr_bank[id_bank] = (bank_addr == id_bank) ? (data_addr_core) : (`REG_SIZE'h0);
		assign	wr_data_bank[id_bank] = (bank_addr == id_bank) ? (wr_data_core[id_curent_core]) : (`REG_SIZE'h0);
		assign	{write_request_bank[id_bank], read_request_bank[id_bank]} = (bank_addr == id_bank) ? (request_core[id_curent_core]) : (2'b00);
	end
endgenerate

generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
	begin
		bank bank_0
	(
		.clk(clk),
		.reset(reset),
		.addr(data_addr_bank[id_bank]),
		.data_in(wr_data_bank[id_bank]),
		.read_enable(read_request_bank[id_bank]),
		.write_enable(write_request_bank[id_bank]),
		.data_out(rd_data_bank[id_bank])
	);
	end
endgenerate



always @(posedge clk)
begin
	id_last_core <= (~reset) ? id_current_core : `CORE_ID_SIZE'h0;
end

always @(posedge clk)
begin
	id_last_bank <= (~reset) ? bank_addr : `BANK_ID_SIZE'h0;
end

always @(posedge clk)
begin
	if (reset)
		last_request_rd <= 1'b0;
	else
		last_request_rd <= ((~skip) && (read_request_bank != `BANK_ID_SIZE'h0));
end

endmodule
