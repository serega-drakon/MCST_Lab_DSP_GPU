module clk_div2 (//
	input		clk,
	input		rst,
	output reg	clk_div2
);

always @(posedge clk)
begin
	clk_div2 <= (rst) ? 1'b0 : ~clk_div2;
end

endmodule
