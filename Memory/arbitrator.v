module arbitrator
(
	input 		clk,
	input		reset,
	input	[31:0]	enable,
	input	[191:0]	addr,
	input	[127:0]	wr_data,
	output	[127:0]	rd_data,
	output	[15:0]	val
);

reg	[3:0] 	id_curent_core;	

function [7:0]	form_wr_data;
	input	[127:0]	wr_data_all;
	input	[3:0]	id_core;
begin
	form_wr_data = {wr_data_all[id_core * 8 + 7],
			wr_data_all[id_core * 8 + 6],
			wr_data_all[id_core * 8 + 5],
			wr_data_all[id_core * 8 + 4],
			wr_data_all[id_core * 8 + 3],
			wr_data_all[id_core * 8 + 2],
			wr_data_all[id_core * 8 + 1],
			wr_data_all[id_core * 8 ]};
end
endfunction

function [11:0]	form_addr;
	input	[191:0]	addr_all;
	input	[3:0]	id_core;
begin
	form_addr = {	addr_all[id_core * 12 + 11],
			addr_all[id_core * 12 + 10],
			addr_all[id_core * 12 + 9],
			addr_all[id_core * 12 + 8],
			addr_all[id_core * 12 + 7],
			addr_all[id_core * 12 + 6],
			addr_all[id_core * 12 + 5],
			addr_all[id_core * 12 + 4],
			addr_all[id_core * 12 + 3],
			addr_all[id_core * 12 + 2],
			addr_all[id_core * 12 + 1],
			addr_all[id_core * 12 ]};
end
endfunction

function [1:0] form_request;	
	input	[31:0]	request_all;
	input	[3:0]	id_core;
begin
	form_request = {request_all[id_core * 2 + 1], request_all[id_core * 2]};
end
endfunction

function [4:0]	find_id_core;	
	input [3:0]	start_search;	
	input [31:0]	request_all;	
	input [3:0]	iteration;	
begin
	if(iteration == 4'b1111)
	begin
		find_id_core = {1'b1, start_search};
	end
	else if(form_request(request_all,start_search + 1) == 0)
	begin
		find_id_core = find_id_core(start_search + 1, request_all, iteration + 1);
	end
	else
	begin
		find_id_core = start_search + 1;
	end
end
endfunction

wire		skip;
wire	[3:0]	id_request_core;
wire	[1:0]	request_core;
wire	[3:0]	bank_addr;
wire	[7:0]	data_addr_core;
wire	[7:0]	wr_data_bank;

assign	{skip, id_request_core} = find_id_core(id_curent_core, enable, 0);
assign	request_core = form_request(enable, id_request_core);
assign	{bank_addr, data_addr_core} = form_addr(addr, id_request_core);
assign	wr_data_bank = form_wr_data(wr_data, id_request_core);

wire	[7:0]	data_addr	[15:0];
wire	[7:0]	wr_data_0	[15:0];
wire	[15:0]	read_request_bank;
wire	[15:0]	write_request_bank;
wire	[7:0]	rd_data_bank	[15:0];
wire	[15:0]	valid_bank;
wire	[7:0]	rd_data_core	[15:0];
wire	[15:0]	valid_core;

genvar i;
generate for(i = 0; i < 16; i = i + 1)
	begin
		assign	data_addr[i] = (bank_addr == i) ? (data_addr_core) : (8'b00000000);
		assign	read_request_bank[i] = (bank_addr == i) ? (request_core[0]) : (1'b0);
		assign	write_request_bank[i] = (bank_addr == i) ? (request_core[1]) : (1'b0);
		assign	wr_data_0[i] = (bank_addr == i) ? (wr_data_bank) : (8'b00000000);
		assign	rd_data_core[i] = (id_request_core == i) ? (rd_data_bank[bank_addr]) : (8'b00000000);
		assign	valid_core[i] = (id_request_core == i);
	end
endgenerate

genvar j;
generate for(j = 0; j < 16; j = j + 1)
	begin
		bank bank_0
	(
		.clk(clk),
		.reset(reset),
		.addr(data_addr[j]),
		.data_in(wr_data_0[j]),
		.read_enable(read_request_bank[j]),
		.write_enable(write_request_bank[j]),
		.data_out(rd_data_bank[j])
	);
	end
endgenerate


always @(posedge clk)
begin
	if (reset)
	begin
		id_curent_core <= 0;
	end
	else
	begin
		id_curent_core <= id_request_core;
	end
end

always @(posedge clk)
begin
	
		
end

endmodule
