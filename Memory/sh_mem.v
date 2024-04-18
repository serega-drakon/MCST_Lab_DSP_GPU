`include"IncAll.def.v"
`include"bank.v"
`include"find_id_core.v"

module sh_mem
(
	input	wire 				clk,
	input	wire				reset,
	input	wire	[`ENABLE_BUS_RANGE]	enable,
	input	wire	[`ADDR_BUS_RANGE]	addr,
	input	wire	[`REG_BUS_RANGE]	wr_data,
	output	wire	[`REG_BUS_RANGE]	rd_data,
	output	wire	[`CORES_RANGE]		ready,

	input	wire				vga_en,  //signal from scheduler for vga print
	input	wire	[`ADDR_RANGE]		vga_addr,
	output	wire	[`REG_RANGE]		vga_data,
	output	wire				vga_end
);

reg				vga_stop;
reg	[`REG_RANGE]		vga_count;
wire	[`REG_RANGE]		vga_rd_data_bank		[`BANKS_RANGE];

always @(posedge clk)
begin
	if(reset)
	begin
		vga_stop <= 1'b0;
	end
	else
	begin
		vga_stop <= (vga_en | (vga_count == `REG_SIZE'd255)) ? ~vga_stop : vga_stop;
	end
end

always @(posedge clk)
begin
	if(reset)
	begin
		vga_count <= 1'b0;
	end
	else
	begin
		vga_count <= (vga_stop | vga_en) ? vga_count + 1 : `REG_SIZE'b0;
	end
end

wire	[`BANKS_RANGE]	vga_addr_bank;
wire	[`REG_RANGE]	vga_addr_reg;

//assign	vga_end = (vga_count == `ADDR_SIZE'd255);
assign 	vga_end = ~(vga_en | vga_stop);
assign	{vga_addr_bank, vga_addr_reg} = vga_addr;
assign	vga_data = vga_rd_data_bank[vga_addr_bank];

reg	[`CORE_ID_RANGE] 	id_last_core	[`BANKS_RANGE];
reg	[`BANK_ID_RANGE]	id_last_bank	[`CORES_RANGE];
reg	[`CORES_RANGE]		last_request_rd;
reg	[`CORES_RANGE]		last_request_wr;

wire	[`ENABLE_RANGE]		request_core	[`CORES_RANGE];
wire	[`REG_RANGE]		wr_data_core	[`CORES_RANGE];
wire	[`ADDR_RANGE]		addr_core	[`CORES_RANGE];
wire	[`REG_RANGE]		rd_data_core	[`CORES_RANGE];

wire	[`BANKS_RANGE]		skip;
wire	[`CORE_ID_RANGE]	id_current_core		[`BANKS_RANGE];
wire	[`BANK_ID_RANGE]	bank_addr		[`CORES_RANGE];
wire	[`REG_RANGE]		data_addr_core		[`CORES_RANGE];
wire	[`CORES_RANGE]		request_core_mask	[`BANKS_RANGE];

wire	[`REG_RANGE]		data_addr_bank		[`BANKS_RANGE];
wire	[`REG_RANGE]		wr_data_bank		[`BANKS_RANGE];
wire	[`BANKS_RANGE]		read_request_bank;
wire	[`BANKS_RANGE]		write_request_bank;
wire	[`REG_RANGE]		rd_data_bank		[`BANKS_RANGE];

wire core_is_curr [`CORES_RANGE];

genvar id_core;
generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_request
	assign	request_core[id_core] = enable[(id_core + 1) * 2 - 1: id_core * 2];
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
	assign	{bank_addr[id_core], data_addr_core[id_core]} = addr[(id_core + 1) * `ADDR_SIZE - 1: id_core * `ADDR_SIZE];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_ready
	assign	ready[id_core] = ((last_request_rd[id_core]) | ((request_core[id_core] == 2'b10) & (core_is_curr[id_core])));//?
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_rd_data_core
	assign	rd_data_core[id_core] = (last_request_rd[id_core]) ? rd_data_bank[id_last_bank[id_core]] : `REG_SIZE'h0;
end
endgenerate


/*?*/
genvar id_bank;
generate for (id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
begin: form_request_mask
	for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
	begin: form_request_0
		assign	request_core_mask[id_bank][id_core] = ((bank_addr[id_core] == id_bank) && (request_core[id_core] != 0));
	end
end
endgenerate

generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
begin: form_core_queue 
	find_id_core find_id_core_0
	(
		.mask(request_core_mask[id_bank]),
		.start_search(id_last_core[id_bank]),
		.result({skip[id_bank], id_current_core[id_bank]})
	);
end
endgenerate

generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
	begin:connection_wires
		assign	data_addr_bank[id_bank] =
			(vga_stop) ? (vga_count) :
			(~skip[id_bank]) ? (data_addr_core[id_current_core[id_bank]]) : (`REG_SIZE'h0);
		assign	wr_data_bank[id_bank] =
			(~skip[id_bank]) ? (wr_data_core[id_current_core[id_bank]]) : (`REG_SIZE'h0);
		assign	{write_request_bank[id_bank], read_request_bank[id_bank]} =
			(vga_stop) ? (2'b01) :
			(~skip[id_bank]) ? (request_core[id_current_core[id_bank]]) : (2'b00);
	end
endgenerate

generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
	begin:connection_banks
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

		bank bank_copy
	(
		.clk(clk),
		.reset(reset),
		.addr((vga_stop) ? vga_count : vga_addr_reg),
		.data_in(rd_data_bank[id_bank]),
		.read_enable((vga_stop) ? 1'b0 : 1'b1),
		.write_enable((vga_stop) ? 1'b1 : 1'b0),
		.data_out(vga_rd_data_bank[id_bank])
	);
	end
endgenerate


generate for(id_bank = 0; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1)
	begin:last_core
		always @(posedge clk)
		begin
			id_last_core[id_bank] <= (~reset) ? id_current_core[id_bank] : `CORE_ID_SIZE'h0;
		end
	end
endgenerate

generate for(id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
	begin:last_bank
		always @(posedge clk)
		begin
			id_last_bank[id_core] <= (~reset) ? bank_addr[id_core] : `BANK_ID_SIZE'h0;
		end
	end
endgenerate

wire mid_core_is_curr [`CORES_RANGE][`BANKS_RANGE];

generate
	for(id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1) begin : curr_core_loop
		assign mid_core_is_curr[id_core][0] = ((id_current_core[0] == id_core) && (~skip[0]));
		for(id_bank = 1; id_bank < `NUM_OF_BANKS; id_bank = id_bank + 1) begin : curr_core_loop_
			assign mid_core_is_curr[id_core][id_bank] = ((id_current_core[id_bank] == id_core) && (~skip[id_bank]))
				|| mid_core_is_curr[id_core][id_bank - 1];
		end
		assign core_is_curr[id_core] =  mid_core_is_curr[id_core][`NUM_OF_BANKS - 1];
	end
endgenerate

generate for(id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
	begin:last_rd
		always @(posedge clk)
		begin
			if (reset)
				last_request_rd[id_core] <= 1'b0;
			else
				last_request_rd[id_core] <=
					((~skip[id_last_bank[id_core]]) && (read_request_bank[id_last_bank[id_core]] != 1'b0)
						&& core_is_curr[id_core]);
		end		//fixme
	end
endgenerate

generate for(id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
	begin:last_wr
		always @(posedge clk)
		begin
			if (reset)
				last_request_wr[id_core] <= 1'b0;
			else
				last_request_wr[id_core] <=
					((~skip[bank_addr[id_core]])
						&& (write_request_bank[bank_addr[id_core]] != 1'b0)
						&& core_is_curr[id_core] && (~last_request_wr[id_core]));


				//last_request_wr[id_core] <=
				//	((~skip[bank_addr[id_core]]) & (write_request_bank[bank_addr[id_core]] != 1'b0)
				//		& (last_request_wr[id_core] == 1'b0)); //fixme
		end
	end
endgenerate

//debug
wire [`CORE_ID_RANGE] debug = id_current_core[0];

endmodule
