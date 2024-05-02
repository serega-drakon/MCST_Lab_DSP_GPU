`include"../SharedInc/IncAll.def.v"
`include "sh_mem.v"

module top_arb;
reg 	clk, reset;

reg	[1:0]		core_request	[`CORES_RANGE];
reg	[`ADDR_RANGE]	core_addr	[`CORES_RANGE];
reg	[`REG_RANGE]	core_wr_data	[`CORES_RANGE];
wire	[`REG_RANGE]	core_rd_data	[`CORES_RANGE];
wire	[`CORES_RANGE]	core_ready;

wire	[`ENABLE_BUS_RANGE]	enable;
wire	[`ADDR_BUS_RANGE]	addr;
wire	[`REG_BUS_RANGE]	wr_data;
wire	[`REG_BUS_RANGE]	rd_data;

genvar id_core;
generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_enable
	assign	enable[id_core * 2 + 1: id_core * 2] = core_request[id_core];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_addr
	assign	addr[(id_core + 1) * `ADDR_SIZE - 1: id_core * `ADDR_SIZE] = core_addr[id_core];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_wr_data
	assign	wr_data[(id_core + 1) * `REG_SIZE - 1: id_core * `REG_SIZE] = core_wr_data[id_core];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: form_rd_data
	assign	core_rd_data[id_core] = rd_data[(id_core + 1) * `REG_SIZE - 1: id_core * `REG_SIZE];
end
endgenerate

generate for (id_core = 0; id_core < `NUM_OF_CORES; id_core = id_core + 1)
begin: zero
	initial
	begin
		core_request[id_core] = 0;
		core_addr[id_core] = 0;
		core_wr_data[id_core] = 0;
	end
end
endgenerate

initial	
begin
	clk = 0;
	reset = 0;
	#2 reset = 1;
	#2 reset = 0;
end
always 	#1 clk = ~clk;

sh_mem my_arbitrator
(
	.clk(clk),
	.reset(reset),
	.enable(enable),
	.addr(addr),
	.wr_data(wr_data),
	.rd_data(rd_data),
	.ready(core_ready)
);

initial
begin
	#5;
	core_request[2] = 2'b10; // write
	core_addr[2] = {4'd0, 8'd0};
	core_wr_data[2] = 8'd1;
	core_request[3] = 2'b10; // write
	core_addr[3] = {4'd1, 8'd1};
	core_wr_data[3] = 8'd2;
	#2;
	$write("%b \n", (core_ready[2] == 1));
	$write("%b \n", (core_ready[3] == 1));
	#2;
	core_request[2] = 2'b01; // read
	core_addr[2] = {4'd0, 8'd0};
	core_request[3] = 2'b01; // read
	core_addr[3] = {4'd1, 8'd1};
	#2;
	$write("%b, %b \n", (core_ready[2] == 1),(core_rd_data[2] == 1));
	$write("%b, %b \n", (core_ready[3] == 1),(core_rd_data[3] == 2));
	core_request[2] = 0;
	core_request[3] = 0;
	#2;
	core_request[1] = 2'b10;
	core_request[3] = 2'b10;
	core_request[5] = 2'b10;
	core_request[7] = 2'b10;
	core_request[9] = 2'b10;
	core_request[11] = 2'b10;
	core_request[13] = 2'b10;
	core_request[15] = 2'b10;
	core_addr[1] = {4'd0, 8'd0};
	core_addr[3] = {4'd0, 8'd1};
	core_addr[5] = {4'd0, 8'd2};
	core_addr[7] = {4'd0, 8'd3};
	core_addr[9] = {4'd0, 8'd4};
	core_addr[11] = {4'd0, 8'd5};
	core_addr[13] = {4'd0, 8'd6};
	core_addr[15] = {4'd0, 8'd7};
	core_wr_data[1] = 8'd0;
	core_wr_data[3] = 8'd1;
	core_wr_data[5] = 8'd2;
	core_wr_data[7] = 8'd3;
	core_wr_data[9] = 8'd4;
	core_wr_data[11] = 8'd5;
	core_wr_data[13] = 8'd6;
	core_wr_data[15] = 8'd7;
end

initial
begin
	#1000	$stop;
end
endmodule
