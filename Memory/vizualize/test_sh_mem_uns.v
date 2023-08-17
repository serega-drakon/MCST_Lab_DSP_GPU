`include"../SharedInc/IncAll.def.v"
`include "sh_mem_uns.v"

module top_arb_uns;
reg 	clk, reset;

reg	[1:0]		core_request	[`CORES_RANGE];
reg	[`ADDR_RANGE]	core_addr	[`CORES_RANGE];
reg	[`REG_RANGE]	core_wr_data	[`CORES_RANGE];
wire	[`REG_RANGE]	core_rd_data	[`CORES_RANGE];
wire	[`CORES_RANGE]	core_ready;
reg			dump;

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
	dump = 0;
end
always 	#1 clk = ~clk;

sh_mem_uns my_arbitrator
(
	.clk(clk),
	.reset(reset),
	.enable(enable),
	.addr(addr),
	.wr_data(wr_data),
	.rd_data(rd_data),
	.ready(core_ready),
	.dump(dump)
);

integer f;

initial
begin
	#6;
	core_request[2] = 2'b10; // write
	core_addr[2] = {4'd5, 8'd123};
	core_wr_data[2] = 8'd45;
	#2;
	$write("%b \n", (core_ready[2] == 1));
	core_request[2] = 2'b01; // read
	core_addr[2] = {4'd5, 8'd123};
	#2;
	$write("%b, %b \n", (core_ready[2] == 1), (core_rd_data[2] == 8'd45));
	core_request[2] = 2'b10;
	core_addr[2] = {4'd5, 8'd123};
	core_wr_data[2] = 8'd76;
	#2;
	$write("%b \n", (core_ready[2] == 1));
	core_request[2] = 2'b01;
	core_addr[2] = {4'd5, 8'd123};
	#2;
	$write("%b, %b \n", (core_ready[2] == 1), (core_rd_data[2] == 8'd76));
	core_request[2] = 2'b00;
	core_request[4] = 2'b10;
	core_addr[4] = {4'd8, 8'd23};
	core_wr_data[4] = 8'd67;
	$write("%b \n", (core_ready[4] == 0));
	#2;
	$write("%b \n", (core_ready[4] == 1));
	core_request[4] = 2'b00;
	#2;
	$write("%b \n", (core_ready[4] == 0));
	#2;
	core_request[4] = 2'b01;
	core_addr[4] = {4'd8, 8'd23};
	#2;
	$write("%b, %b \n", (core_ready[4] == 1), (core_rd_data[4] == 8'd67));
	core_request[4] = 2'b00;
	f = $fopen(`FILE, "w");
	$fclose(f);
	dump = 1;
end

initial
begin
	#10000	$stop;
end
endmodule
