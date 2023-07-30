`timescale 1ns/100ps
module top;
reg 	clk, reset;

reg	[7:0]	addr_in;
reg	[7:0]	data_in;
reg		r_en;
reg		w_en;
wire	[7:0]	d_o;
wire		v_o;

initial	
begin
	r_en = 0;
	w_en = 0;
	clk = 0;
	reset = 0;
	#2 reset = 1;
	#2 reset = 0;
end
always 	#1 clk = ~clk;

bank my_bank
(
	.clk(clk),
	.reset(reset),
	.addr(addr_in),
	.data_in(data_in),
	.read_enable(r_en),
	.write_enable(w_en),
	.data_out(d_o),
	.valid_out(v_o)
);

initial
begin
	#5;
	r_en = 1;
	addr_in = 0;
	#2;
	$write("%b \n",(v_o == 0));
	#2;
	r_en = 0;
	w_en = 1;
	addr_in = 9;
	data_in = 24;
	#2;
	r_en = 1;
	w_en = 0;
	addr_in = 9;
	#2;
	$write("%b, %b \n",(v_o == 1), (d_o == 24));
	r_en = 0;
	w_en = 1;
	addr_in = 255;
	data_in = 145;
	#2;
	r_en = 1;
	w_en = 0;
	addr_in = 255;
	#2;
	$write("%b, %b \n",(v_o == 1), (d_o == 145));
	r_en = 1;
	w_en = 0;
	addr_in = 9;
	#2;
	$write("%b, %b \n",(v_o == 1), (d_o == 24));
	r_en = 0;
	w_en = 1;
	addr_in = 9;
	data_in = 98;
	#2;
	r_en = 1;
	w_en = 0;
	addr_in = 9;
	#2;
	$write("%b, %b \n",(v_o == 1), (d_o == 98));
end

initial
begin
	#1000	$stop;
end

endmodule
